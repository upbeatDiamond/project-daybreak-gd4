extends Node

# Contains code relating to SQLite bindings
# This class is dedicated to the fetching and manipulation of database contents

# We're going to need a lot of refactoring to account for changes in not only gameplay plans ...
# ... but also data being split across multiple tables.


#const BattleAI = preload("res://battle/monster_battle_ai.gd")

var db : SQLite = null

const verbosity_level : int = SQLite.VERBOSE

# Used for balance patches and backwards compatibility with future monster additions
var db_name_patch := "res://database/patchdata"

# 3 Databases intended to be used for save file security.
# Active updates as you play, but some players might not want to autosave.
var db_name_user_active := "user://database/save_active"
# Stable is created when the player manually hits the 'save' button
var db_name_user_stable := "user://database/save_stable"
# Backup is intended to avoid any corruption errors, but so far doesn't do much.
var db_name_user_backup := "user://database/save_backup"
# And this file acts as intermediary between all of the 3 user save files.
var json_name_user_pidgeonhole := "user://database/pidgeonhole"


var table_name_monster := "monster"
var table_name_user_monster := "monster"
var table_name_user_gamepiece := "gamepiece"
#var table_name_player := "person"
#var table_name_relationship := "character"

# Enums with Table = Key, Property = Value
# Table_col : [ obj property name, fallback ]
# ALT- tblcol : [ [obj property name, property index/modifier], fallback ]
# Any property name that includes brackets should be split off and parsed.
var tkpv_monster = {
	"status_effects": 	 { "fallback": "" },
	"franchise_ID": 	 { "fallback": 0 },
	"species_ID": 		 { "property": "species", "fallback": -1 },
	"variant_ID": 		 { "fallback": 0 },
	"umid": 			 { "property": "umid", "fallback": -1 }, #stats_growth
	"current_health": 	 { "property": "stats_current", "index":GlobalMonster.BattleStats.HEALTH, "fallback": -1 },
	"current_spirit": 	 { "property": "stats_current", "index":GlobalMonster.BattleStats.SPIRIT, "fallback": -1 },
	"current_attack": 	 { "property": "stats_current", "index":GlobalMonster.BattleStats.ATTACK, "fallback": -1 },
	"current_defense": 	 { "property": "stats_current", "index":GlobalMonster.BattleStats.DEFENSE, "fallback": -1 },
	"current_speed": 	 { "property": "stats_current", "index":GlobalMonster.BattleStats.SPEED, "fallback": -1 },
	"current_evasion": 	 { "property": "stats_current", "index":GlobalMonster.BattleStats.EVASION, "fallback": -1 },
	"current_intimidate":{ "property": "stats_current", "index":GlobalMonster.BattleStats.INTIMIDATION, "fallback": -1 },
	"current_resolve": 	 { "property": "stats_current", "index":GlobalMonster.BattleStats.RESOLVE, "fallback": -1 },
	"current_mana": 	 { "property": "stats_current", "index":GlobalMonster.BattleStats.MANA, "fallback": -1 },
	"max_health": 		 { "property": "stats_current", "index":GlobalMonster.BattleStats.HEALTH, "fallback": -1 },
	"max_spirit": 		 { "property": "stats_current", "index":GlobalMonster.BattleStats.SPIRIT, "fallback": -1 },
	"max_attack": 		 { "property": "stats_current", "index":GlobalMonster.BattleStats.ATTACK, "fallback": -1 },
	"max_defense": 		 { "property": "stats_current", "index":GlobalMonster.BattleStats.DEFENSE, "fallback": -1 },
	"max_speed": 		 { "property": "stats_current", "index":GlobalMonster.BattleStats.SPEED, "fallback": -1 },
	"max_evasion": 		 { "property": "stats_current", "index":GlobalMonster.BattleStats.EVASION, "fallback": -1 },
	"max_intimidate": 	 { "property": "stats_current", "index":GlobalMonster.BattleStats.INTIMIDATION, "fallback": -1 },
	"max_resolve": 		 { "property": "stats_current", "index":GlobalMonster.BattleStats.RESOLVE, "fallback": -1 },
	"max_mana": 		 { "property": "stats_current", "index":GlobalMonster.BattleStats.MANA, "fallback": -1 },
	"ability": 			 { "property": "ability", "fallback":  0},
	"exp": 				 { "property": "experience", "fallback":  0},
	"level": 			 { "property": "level", "fallback":  1},
	"name": 			 { "property": "birth_name", "fallback":  "John Smith"},
}

var tkpv_gamepiece = {
	"gpid": 	 		{"property": "unique_id", 			"fallback": -1},
	"umid": 	 		{"property": "umid", 				"fallback": -1},
	"move_queue": 	 	{"property": "move_queue", 			"fallback": []},
	"position_known": 	{"property": "position_is_known", 	"fallback": false},
	"target_position": 	{"property": "target_position", 	"fallback": Vector2(0,0) },
	"traversal_mode": 	{"property": "traversal_mode", 		"fallback": Gamepiece.TraversalMode.STANDING },
	"target_map":		{"property": "target_map", 			"fallback": -1 },
	"current_map":		{"property": "current_map", 		"fallback": -1 },
	"current_position":	{"property": "global_position", 	"fallback": Vector2i(0,0)},
}

var tkpv_level_map = {
	"map_id": {"property":"map_index", "fallback":-1},
	"map_path": {"property":"scene_file_path", "fallback":""},
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func exists_monster( monster ) -> bool:
	
	var row_array = ["name"]
	
	db = SQLite.new()
	db.path = db_name_user_active
	db.open_db()
	
	var query_result = db.select_rows( table_name_monster, str("umid = ", monster.umid), row_array );
	
	db.close_db()
	
	if (query_result is Array && query_result.size() > 0):
		return true
	
	return false

## concept code:
#var pre_bind = GlobalRuntime.multiply_string(" ? ", cols.size, "," )
#var bind = vals
#var query_template = str( "INSERT OR REPLACE INTO ", table_name, " ( " )
#for col in cols:
	#query_template = str(query_template, " ", col, ", ")
#query_template = str(query_template,   " ) values ( ",  pre_bind,  " )" )
#query_with_bindings( query_template, bind );

func game_to_database(thing:Object, tablekey_propval:Dictionary, target_db_path:String, \
target_table_name:String, _query_conditions:String=""  ):
	
	var row_dict : Dictionary = {}
	#var current_propval
	var cols = tablekey_propval.keys()
	var vals = cols.duplicate()
	
	# For each item in the dictionary, copy over its values, but simplified/realized.
	for key in cols:
		# If the result is an array, it's likely a value pair.
		# While storing an array is bad practice, it needs an exit path.
		if tablekey_propval[key] is Dictionary: #{ ? : [ ?* ] }
			
			if tablekey_propval[key].has( "property" ) and thing != null:
				row_dict[key] = thing.get( tablekey_propval[key]["property"] )
				if (row_dict[key] is Array or row_dict[key] is Dictionary) and tablekey_propval[key].has( "index" ):
					row_dict[key] = thing.get(tablekey_propval[key]["property"])[ tablekey_propval[key]["index"] ]
					#print( thing, thing.get(tablekey_propval[key]["property"]) )
					#print(row_dict[key], " y'know?")
					
					## if the reassignment failed, revert.
					## it might be better to make a new variable for this instead?
					#if row_dict[key] == null:
						#row_dict[key] = thing.get( tablekey_propval[key]["property"] )
			else:
				row_dict[key] = null
			
			if row_dict[key] == null:
				if tablekey_propval[key].has( "fallback" ):
					row_dict[key] = tablekey_propval[key]["fallback"]
		else:  # ?
			row_dict[key] = tablekey_propval[key]
		
		vals[ cols.find(key) ] = row_dict[key]
	
	# Any non-atomic types should be converted into a byte array
	var i:int = vals.size() - 1
	while i > 0:
		vals[i] = db_wrap(vals[i])
		i -= 1;
		pass
	
	db = SQLite.new()
	db.path = target_db_path
	db.open_db()
	#var row_array = [row_dict]
	#var success = db.insert_rows( target_table_name, row_array )
	#if !success:
	#	db.update_rows( target_table_name, query_conditions, row_dict )
	
	#print("nbind")
	var pre_bind = GlobalRuntime.multiply_string(" ? ", cols.size(), "," )
	#var bind = vals
	#print("bind")
	var query_template = str( "INSERT OR REPLACE INTO ", target_table_name, " ( " )
	for col in cols:
		query_template = str(query_template, " ", col, ", ")
	query_template = str(query_template.rstrip(', '),   " ) values ( ",  pre_bind,  " )" )
	print(query_template)
	var _success = db.query_with_bindings( query_template, vals );
	
	db.close_db()
	
	pass


func database_to_game(thing:Object, tablekey_propval:Dictionary, target_db_path:String, target_table_name:String, query_conditions:String ):
	
	var row_dict : Dictionary = {}
	#var current_propval
	
	var selected_columns : Array = tablekey_propval.keys()
	
	db = SQLite.new()
	db.path = target_db_path#db_name_user_active
	db.open_db()
	
	var fetched:Array = db.select_rows( target_table_name, query_conditions, selected_columns )
	
	# For each item in the dictionary, copy over its values, but simplified/realized.
	for key in selected_columns:
		# If the result is an array, it's likely a value pair.
		# While storing an array is bad practice, it needs an exit path.
		if tablekey_propval[key] is Dictionary: #{ ? : [ ?* ] }
			
			if tablekey_propval[key].has( "property" ):
				row_dict[key] = thing.get( tablekey_propval[key]["property"] )
				if (row_dict[key] is Array or row_dict[key] is Dictionary) and tablekey_propval[key].has( "index" ):
					row_dict[key] = row_dict.get( tablekey_propval[key]["index"] )
					
					# if the reassignment failed, revert.
					# it might be better to make a new variable for this instead?
					if row_dict[key] == null:
						row_dict[key] = thing.get( tablekey_propval[key]["property"] )
						# thing.set(property <-- fetched[key])
						thing.set(tablekey_propval[key]["property"], db_unwrap(fetched.front()[ key ]) ) # selected_columns.find(key)
					else:
						# thing.set(property[index] <-- fetched[key])
						thing.set(tablekey_propval[key]["property"] [tablekey_propval[key]["index"]], db_unwrap(fetched.front()[ selected_columns.find(key) ]))
				else:
					# thing.set(property <-- fetched[key])
					thing.set(tablekey_propval[key]["property"], db_unwrap(fetched.front()[ key ])) # selected_columns.find(key)
	
	db.close_db()
	
	pass

# To be called by GlobalMonsterSpawner
func store_monster( monster ):
	game_to_database( monster, tkpv_monster, db_name_user_active, table_name_monster, \
	str("UMID = ", monster.umid) )


func save_monster( monster ):
	if( exists_monster( monster ) ):
		update_monster( monster )
	else:
		store_monster( monster )


# Contains code to save monster character to database
func update_monster( monster ):
	database_to_game( monster, tkpv_monster, db_name_user_active, table_name_monster, \
	str("UMID = ", monster.umid) )


## Need to update the selected columns here.
#func load_monster( monster ):
	#
	#var selected_columns : Array = ["current_health", "current_spirit", 
									#"current_attack", "current_defense", 
									#"current_speed", "current_evasion", 
									#"current_intimidate", "current_resolve", 
									#"current_mana", "max_health", "max_spirit", 
									#"max_attack", "max_defense", "max_speed", 
									#"max_evasion", "max_intimidate", "max_resolve", 
									#"max_mana", "ability", "exp", "level", 
									#"name", "item_held"];
	#
	#var summary_dict : Dictionary = Dictionary();
	#
	#db = SQLite.new()
	#db.path = db_name_user_active
	#db.open_db()
	#
	#var fetched:Array = db.select_rows( table_name_monster, str("umid = ", monster.umid), selected_columns )
	#
	#db.close_db()
	#
	#pass



func save_gamepiece( gamepiece:Gamepiece ):
	var umid = gamepiece.umid
	
	game_to_database(gamepiece, tkpv_gamepiece, db_name_user_active, "gamepiece", str(" UMID = ", umid )  )
	game_to_database(gamepiece.monster, tkpv_monster, db_name_user_active, "monster", str(" UMID = ", umid )  )
	
	pass



func load_gamepiece( umid:int ) -> Gamepiece:
	
	var gamepiece = Gamepiece.new()
	gamepiece.monster = Monster.new()
	database_to_game(gamepiece, tkpv_gamepiece, db_name_user_active, "gamepiece", str(" UMID = ", umid ) )
	database_to_game(gamepiece.monster, tkpv_monster, db_name_user_active, "monster", str(" UMID = ", umid ) )
	
	return gamepiece


func load_gamepieces_for_map( map_id ) -> Array[Gamepiece]:
	
	var selected_columns : Array = ["umid", "current_position", 
									"current_direction", "current_action"];
	
	#var summary_dict : Dictionary = Dictionary();
	
	db = SQLite.new()
	db.path = db_name_user_active
	db.open_db()
	
	var fetched : Array = db.select_rows( table_name_user_gamepiece, str("current_map = ", map_id), selected_columns )
	var gamepiece_array : Array[Gamepiece] = []
	var gamepiece
	
	# For each table row, use it to build a gamepiece
	for piece_summary in fetched:
		gamepiece = load_gamepiece( piece_summary["umid"] )
		#set_gamepiece_summary( gamepiece, piece_summary );
		gamepiece_array.append( gamepiece )
	
	db.close_db()
	
	return gamepiece_array


func save_player_data():
	pass



func load_player_data():
	pass


# Saves the gametoken & graph connection data
func save_map_link_data():
	pass


# Retrieves the gametoken & graph connection data
func load_map_link_data():
	pass

func load_level_map( map:int ):
	var dummy_map := LevelMap.new()
	dummy_map.map_index = map
	return database_to_game(dummy_map, tkpv_level_map, db_name_user_active, "level_map", str("map_id = ", map) )
	pass

# Saves which file path correlates to the level map index
func save_level_map( map:LevelMap ):
	game_to_database(map, tkpv_level_map, db_name_user_active, "level_map", str("map_id = ", map.map_index) )
	pass

func can_recover_last_state() -> bool:
	var gp_player = load_gamepiece( 0 )
	if gp_player == null:
		return false
	var map_player = load_level_map( gp_player.target_map )
	if map_player == null:
		return false
	gp_player.umid = -1
	gp_player.queue_free()
	map_player.queue_free()
	return true
	pass

func recover_last_state() -> String:
	var gp_player = load_gamepiece( 0 )
	if gp_player == null:
		return ""
	var map_player = load_level_map( gp_player.current_map )
	if map_player == null:
		return ""
	return map_player.scene_file_path
	pass

#func load_level_map( map:LevelMap ):
#	game_to_database(map, tkpv_level_map, db_name_user_active, "level_map", str("map_id = ", map.map_index) )
#	pass

func save_global_data():
	pass



func load_global_data():
	pass


func fetch_save_to_active():
	var db_stage = SQLite.new(); db_stage.path = db_name_user_active; db_stage.open_db()
	var db_commit = SQLite.new(); db_commit.path = db_name_user_stable; db_commit.open_db()
	var db_backup = SQLite.new(); db_backup.path = db_name_user_backup; db_backup.open_db()
	
	var success
	
	success = db_commit.export_to_json( json_name_user_pidgeonhole )
	if success:
		success = db_stage.import_from_json( json_name_user_pidgeonhole )
	else:# success:
		success = db_backup.export_to_json( json_name_user_pidgeonhole )
		if success:
			success = db_stage.import_from_json( json_name_user_pidgeonhole )
			return
		print("Your journal latch seems stuck... We'll just have to see what you remember!")
	
	db_stage.close_db()
	db_commit.close_db()
	db_backup.close_db()



func commit_save_from_active() -> bool:
	var db_stage = SQLite.new(); db_stage.path = db_name_user_active; db_stage.open_db()
	var db_commit = SQLite.new(); db_commit.path = db_name_user_stable; db_commit.open_db()
	var db_backup = SQLite.new(); db_backup.path = db_name_user_backup; db_backup.open_db()
	
	var success
	
	success = db_commit.export_to_json( json_name_user_pidgeonhole )
	if success:
		success = db_backup.import_from_json( json_name_user_pidgeonhole )
	
	success = db_stage.export_to_json( json_name_user_pidgeonhole )
	if success:
		success = db_commit.import_from_json( json_name_user_pidgeonhole )
	
	db_stage.close_db()
	db_commit.close_db()
	db_backup.close_db()
	
	return success

func db_wrap(thing):
	match typeof(thing):
		TYPE_BOOL, TYPE_INT:
			return thing
		TYPE_STRING, TYPE_STRING_NAME:
			return str(thing)
	return var_to_bytes(thing)

func db_unwrap(thing):
	if typeof(thing) == TYPE_PACKED_BYTE_ARRAY:
		return bytes_to_var(thing)
	return thing

func validate_umid( umid:int=0 ) -> int:
	
	# if UMID is taken, increment to the first untaken value
	# if all taken values are used, start from the start?
	# maybe use a binary tree type search?
	# else:
	# SELECT MIN(id + 1) AS next_id
	# FROM my_table
	# WHERE (id + 1) >= {{umid}} AND (id + 1) NOT IN (SELECT id FROM my_table)
	#
	
	return umid


# I call this a 'struct' because I like the C langauge.
#func load_move_effectiveness_struct(move_id):
#	print( sqrt(-1)/0 ); # Because I don't know how throwing and catching works in GD 4
#	pass
