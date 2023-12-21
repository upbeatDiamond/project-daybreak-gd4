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
	"UMID": 			 { "property": "umid", "fallback": -1 }, #stats_growth
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
	"current_position":	{"property": "current_position", 	"fallback": Vector2i(0,0)},
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


func get_monster_summary( monster:Monster ) -> Dictionary:
	var summary : Dictionary = Dictionary()
	
	summary["status_effects"]	= []
	summary["franchise_ID"]		= 0
	summary["species_ID"]		= monster.species
	summary["variant_ID"]		= 0
	summary["UMID"]				= monster.umid
	summary["current_health"] 	= monster.stats_current[GlobalMonster.BattleStats.HEALTH]
	summary["current_spirit"] 	= monster.stats_current[GlobalMonster.BattleStats.SPIRIT]
	summary["current_attack"] 	= monster.stats_current[GlobalMonster.BattleStats.ATTACK]
	summary["current_defense"] 	= monster.stats_current[GlobalMonster.BattleStats.DEFENSE]
	summary["current_speed"] 	= monster.stats_current[GlobalMonster.BattleStats.SPEED]
	summary["current_evasion"] 	= monster.stats_current[GlobalMonster.BattleStats.EVASION]
	summary["current_intimidate"] = monster.stats_current[GlobalMonster.BattleStats.INTIMIDATION]
	summary["current_resolve"] 	= monster.stats_current[GlobalMonster.BattleStats.RESOLVE]
	summary["current_mana"] 	= monster.stats_current[GlobalMonster.BattleStats.MANA]
	summary["max_health"] 		= monster.stats_base[GlobalMonster.BattleStats.HEALTH]
	summary["max_spirit"] 		= monster.stats_base[GlobalMonster.BattleStats.SPIRIT]
	summary["max_attack"] 		= monster.stats_base[GlobalMonster.BattleStats.ATTACK]
	summary["max_defense"] 		= monster.stats_base[GlobalMonster.BattleStats.DEFENSE]
	summary["max_speed"] 		= monster.stats_base[GlobalMonster.BattleStats.SPEED]
	summary["max_evasion"] 		= monster.stats_base[GlobalMonster.BattleStats.EVASION]
	summary["max_intimidate"] 	= monster.stats_base[GlobalMonster.BattleStats.INTIMIDATION]
	summary["max_resolve"]		= monster.stats_base[GlobalMonster.BattleStats.RESOLVE]
	summary["max_mana"] 		= monster.stats_base[GlobalMonster.BattleStats.MANA]
	summary["ability"] 			= monster.ability
	summary["exp"] 				= monster.exp 
	summary["level"] 			= monster.level 
	summary["name"] 			= monster.birth_name 
	summary["funds"] 			= monster.funds 
	
	return summary;

func set_monster_summary( monster:Monster, summary:Dictionary ):
	monster.stats_current[GlobalMonster.BattleStats.HEALTH] 	= summary["current_health"]
	monster.stats_current[GlobalMonster.BattleStats.SPIRIT] 	= summary["current_spirit"]
	monster.stats_current[GlobalMonster.BattleStats.ATTACK] 	= summary["current_attack"]
	monster.stats_current[GlobalMonster.BattleStats.DEFENSE] 	= summary["current_defense"]
	monster.stats_current[GlobalMonster.BattleStats.SPEED] 		= summary["current_speed"]
	monster.stats_current[GlobalMonster.BattleStats.EVASION] 	= summary["current_evasion"]
	monster.stats_current[GlobalMonster.BattleStats.INTIMIDATION] = summary["current_intimidate"]
	monster.stats_current[GlobalMonster.BattleStats.RESOLVE] 	= summary["current_resolve"]
	monster.stats_current[GlobalMonster.BattleStats.MANA] 		= summary["current_mana"]
	monster.stats_base[GlobalMonster.BattleStats.HEALTH] 		= summary["max_health"]
	monster.stats_base[GlobalMonster.BattleStats.SPIRIT] 		= summary["max_spirit"]
	monster.stats_base[GlobalMonster.BattleStats.ATTACK] 		= summary["max_attack"]
	monster.stats_base[GlobalMonster.BattleStats.DEFENSE] 		= summary["max_defense"]
	monster.stats_base[GlobalMonster.BattleStats.SPEED] 		= summary["max_speed"]
	monster.stats_base[GlobalMonster.BattleStats.EVASION] 		= summary["max_evasion"]
	monster.stats_base[GlobalMonster.BattleStats.INTIMIDATION] 	= summary["max_intimidate"]
	monster.stats_base[GlobalMonster.BattleStats.RESOLVE] 		= summary["max_resolve"]
	monster.stats_base[GlobalMonster.BattleStats.MANA] 			= summary["max_mana"]
	monster.ability 	= summary["ability"]
	monster.exp 		= summary["exp"]
	monster.level 		= summary["level"]
	monster.birth_name 	= summary["name"]
	monster.funds 		= summary["funds"] 
	#summary["status_effects"]	= []
	#summary["franchise_ID"]		= 0
	monster.species 	= summary["species_ID"]
	#summary["variant_ID"]		= 0
	monster.umid 		= summary["UMID"]



func get_gamepiece_summary():
	pass



func set_gamepiece_summary( gamepiece:Gamepiece, summary:Dictionary ):
	gamepiece.facing_direction = summary["current_direction"]
	pass


func game_to_database(thing:Object, tablekey_propval:Dictionary, target_db_path:String, target_table_name:String ):
	
	var row_dict : Dictionary
	var current_propval
	
	# For each item in the dictionary, copy over its values, but simplified/realized.
	for key in tablekey_propval.keys():
		# If the result is an array, it's likely a value pair.
		# While storing an array is bad practice, it needs an exit path.
		if tablekey_propval[key] is Dictionary: #{ ? : [ ?* ] }
			
			if tablekey_propval[key].has( "property" ):
				row_dict[key] = thing.get( tablekey_propval[key]["property"] )
				if (row_dict[key] is Array or row_dict[key] is Dictionary) and tablekey_propval[key].has( "index" ):
					row_dict[key] = row_dict[ tablekey_propval[key]["index"] ]
					
					# if the reassignment failed, revert.
					# it might be better to make a new variable for this instead?
					if row_dict[key] == null:
						row_dict[key] = thing.get( tablekey_propval[key]["property"] )
			else:
				row_dict[key] = null
			
			if row_dict[key] == null:
				if tablekey_propval[key].has( "fallback" ):
					row_dict[key] = tablekey_propval[key]["fallback"]
			
			#if (tablekey_propval[key] as Array).size() >= 2: #{ ? : [ ?, ?* ] }
				#
				## We assume that the array is a pair of {property_name, fallback}
				#current_propval = tablekey_propval[key].front()
				#
				## If that's true, good.
				#if thing.get( str(current_propval) ) != null:
					#row_dict[key] = thing.get( current_propval )
				## But if the array pair includes a nested array pair? That's an array probably.
				#elif current_propval is Array and current_propval.size() >= 2:
					#row_dict[key] = thing.get( current_propval.front() )
					#if row_dict[key] != null:
						#row_dict[key] = row_dict[key][ current_propval[1] ]
				#else:
					#row_dict[key] = null
				#
				## If we had no luck parsing the values, we can just use the presumed fallback
				#if row_dict[key] == null:
					#row_dict[key] = (tablekey_propval[key] as Array).back()
					#pass
				#
			#else:  # [ ? ] or []
				#current_propval = (tablekey_propval[key] as Array).duplicate()
				#current_propval.append(null)
				#row_dict[key] = current_propval.back()
				#pass
		else:  # ?
			row_dict[key] = tablekey_propval[key]
	
	# Any non-atomic types should be converted into a byte array
	for key in row_dict.keys():
		row_dict[key] = db_wrap(row_dict[key])
		pass
	
	db = SQLite.new()
	db.path = target_db_path
	db.open_db()
	var row_array = [row_dict]
	db.insert_rows( target_table_name, row_array )
	db.close_db()
	
	pass


func database_to_game(thing:Object, tablekey_propval:Dictionary, target_db_path:String, target_table_name:String, query_conditions:String ):
	
	var row_dict : Dictionary
	var current_propval
	
	var selected_columns : Array = tablekey_propval.keys()
	
	db = SQLite.new()
	db.path = db_name_user_active
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
					row_dict[key] = row_dict[ tablekey_propval[key]["index"] ]
					
					# if the reassignment failed, revert.
					# it might be better to make a new variable for this instead?
					if row_dict[key] == null:
						row_dict[key] = thing.get( tablekey_propval[key]["property"] )
						# thing.set(property <-- fetched[key])
						thing.set(tablekey_propval[key]["property"], db_unwrap(fetched.front()[ selected_columns.find(key) ]) )
					else:
						# thing.set(property[index] <-- fetched[key])
						thing.set(tablekey_propval[key]["property"] [tablekey_propval[key]["index"]], db_unwrap(fetched.front()[ selected_columns.find(key) ]))
				else:
					# thing.set(property <-- fetched[key])
					thing.set(tablekey_propval[key]["property"], db_unwrap(fetched.front()[ selected_columns.find(key) ]))
	
	db.close_db()
	
	pass

# To be called by GlobalMonsterSpawner
func store_monster( monster ):
	
	var row_dict : Dictionary = get_monster_summary( monster );
	
	db = SQLite.new()
	db.path = db_name_user_active
	
	db.open_db()
	
	var row_array = [row_dict]
	
	db.insert_rows( table_name_monster, row_array )
	
	db.close_db()
	
	pass


func save_monster( monster ):
	if( exists_monster( monster ) ):
		update_monster( monster )
	else:
		store_monster( monster )


# Contains code to save monster character to database
func update_monster( monster ):
	
	var row_dict : Dictionary = get_monster_summary( monster ); 
	
	db = SQLite.new()
	db.path = db_name_user_active
	db.open_db()
	
	var query_condition = str("umid = ", monster.umid)
	
	db.update_rows( table_name_monster, query_condition, row_dict )
	
	db.close_db()
	
	pass


# Need to update the selected columns here.
func load_monster( monster ):
	
	var selected_columns : Array = ["current_health", "current_spirit", 
									"current_attack", "current_defense", 
									"current_speed", "current_evasion", 
									"current_intimidate", "current_resolve", 
									"current_mana", "max_health", "max_spirit", 
									"max_attack", "max_defense", "max_speed", 
									"max_evasion", "max_intimidate", "max_resolve", 
									"max_mana", "ability", "exp", "level", 
									"name", "item_held"];
	
	var summary_dict : Dictionary = Dictionary();
	
	db = SQLite.new()
	db.path = db_name_user_active
	db.open_db()
	
	var fetched:Array = db.select_rows( table_name_monster, str("umid = ", monster.umid), selected_columns )
	
	set_monster_summary( monster, fetched[-1] );
	
	db.close_db()
	
	pass



func save_gamepiece( gamepiece:Gamepiece ):
	#game_to_database( gamepiece )
	pass



func load_gamepiece( umid:int ):
	
	var gamepiece = Gamepiece.new()
	database_to_game(gamepiece, tkpv_gamepiece, db_name_user_active, "gamepiece", str(" UMID = ", umid ) )
	database_to_game(gamepiece.monster, tkpv_monster, db_name_user_active, "monster", str(" UMID = ", umid ) )
	
	
	pass


func load_gamepieces_for_map( map_id ) -> Array[Gamepiece]:
	
	var selected_columns : Array = ["umid", "current_position", 
									"current_direction", "current_action"];
	
	var summary_dict : Dictionary = Dictionary();
	
	db = SQLite.new()
	db.path = db_name_user_active
	db.open_db()
	
	var fetched : Array = db.select_rows( table_name_user_gamepiece, str("current_map = ", map_id), selected_columns )
	var gamepiece_array : Array[Gamepiece]
	var gamepiece
	
	# For each table row, use it to build a gamepiece
	for piece_summary in fetched:
		gamepiece = Gamepiece.new()
		set_gamepiece_summary( gamepiece, piece_summary );
		gamepiece_array.append( gamepiece )
	
	db.close_db()
	
	return gamepiece_array


func save_player_data():
	pass



func load_player_data():
	pass


# Saves the gametoken & graph connection data
func save_map_data():
	pass


# Retrieves the gametoken & graph connection data
func load_map_data():
	pass



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



func commit_save_from_active():
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
	
	pass

func db_wrap(thing):
	match typeof(thing):
		TYPE_BOOL, TYPE_INT:
			return thing
		TYPE_STRING, TYPE_STRING_NAME:
			return str(thing)
		_:
			return var_to_bytes(thing)
	pass

func db_unwrap(thing):
	if typeof(thing) == TYPE_PACKED_BYTE_ARRAY:
		return bytes_to_var(thing)
	return thing
	pass

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
func load_move_effectiveness_struct(move_id):
	print( sqrt(-1)/0 ); # Because I don't know how throwing and catching works in GD 4
	pass
