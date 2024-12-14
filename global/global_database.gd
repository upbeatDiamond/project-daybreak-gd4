extends Node

## Contains code relating to SQLite bindings
## This class is dedicated to the fetching and manipulation of database contents

## We're going to need a lot of refactoring to account for changes in not only gameplay plans ...
## ... but also data being split across multiple tables.

var db : SQLite = null

const verbosity_level : int = SQLite.VERBOSE

## Increment based on current date whenever format changes, Beta or higher.
## Also increment beforehand for funsies, I guess?
const VERSION_CODE := 20241210

## Used for balance patches and backwards compatibility with future monster additions
## Please copy this file to user:// upon not finding one in user://
const DB_PATH_PATCH_TEMPLATE := "res://database/patchdata"
const DB_PATH_PATCH_USER := "user://database/patchdata"

## 3 Databases intended to be used for save file security.
## Active updates as you play, but some players might not want to autosave.
const DB_PATH_USER_ACTIVE := "user://database/save_active"
## Stable is created when the player manually hits the 'save' button
const DB_PATH_USER_COMMIT := "user://database/save_stable"
## Backup is intended to avoid any corruption errors, but so far doesn't do much.
const DB_PATH_USER_BACKUP := "user://database/save_backup"
## Reset is to be used if the prior three are all absent.
const DB_PATH_USER_TEMPLATE := "res://database/save_template"

## TODO: make uppercase + update names!
const table_name_monster := "monster"
const table_name_user_monster := "monster"
const table_name_user_gamepiece := "gamepiece"
const table_name_keyval := "variables"
const table_name_species := "species"
#var table_name_player := "person"
#var table_name_relationship := "character"

# Enums with Table = Key, Property = Value
# Table_col : [ obj property name, fallback ]
# ALT- tblcol : [ [obj property name, property index/modifier], fallback ]
# Any property name that includes brackets should be split off and parsed.
const tkpv_monster = {
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

const tkpv_gamepiece = {
	"gpid": 	 		{"property": "unique_id", 			"fallback": -1},
	"umid": 	 		{"property": "umid", 				"fallback": -1},
	"tag": 		 		{"property": "tag", 				"fallback": "Steve?" },
	"move_queue": 	 	{"property": "move_queue", 			"fallback": []},
	"position_known": 	{"property": "position_is_known", 	"fallback": false},
	"target_position": 	{"property": "target_position", 	"fallback": Vector2(0,0) },
	"traversal_mode": 	{"property": "traversal_mode", 		"fallback": Gamepiece.TraversalMode.STANDING },
	"target_map":		{"property": "target_map", 			"fallback": -1 },
	"current_map":		{"property": "current_map", 		"fallback": -1 },
	"current_position":	{"property": "current_position", 	"fallback": Vector2i(0,0)},
	"current_direction":	{"property": "facing_direction", 	"fallback": Vector2i(0,1)},
}

const tkpv_level_map = {
	"map_id": {"property":"map_index", "fallback":-1},
	"map_path": {"property":"scene_file_path", "fallback":""},
}

const CONFIG_FILE_PATH := "user://config.cfg"


# Called when the node enters the scene tree for the first time.
func _ready():
	_regenerate_user_database_folder() 
	## ^ Called every session, to ensure the game has PatchData to work with.
	## This should allow games to be moddable to some extent.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func exists_monster( monster ) -> bool:
	var row_array = ["name"]
	
	db = SQLite.new()
	db.path = DB_PATH_USER_ACTIVE
	db.open_db()
	
	var query_result = db.select_rows( table_name_monster, str("umid = ", monster.umid), row_array );
	db.close_db()
	
	if (query_result is Array && query_result.size() > 0):
		return true
	return false


func load_monster( umid:int ) -> Monster:
	var mon = Monster.new()
	
	mon = database_to_game(mon, tkpv_monster, DB_PATH_USER_ACTIVE, 
			table_name_monster, str("umid = ", umid))
	
	return mon


func game_to_database(thing:Object, tablekey_propval:Dictionary, target_db_path:String, \
target_table_name:String, _query_conditions:String=""  ):
	
	var row_dict : Dictionary = {}
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
	var pre_bind = GlobalRuntime.multiply_string(" ? ", cols.size(), "," )
	var query_template = str( "INSERT OR REPLACE INTO ", target_table_name, " ( " )
	for col in cols:
		query_template = str(query_template, " ", col, ", ")
	query_template = str(query_template.rstrip(', '),   " ) values ( ",  pre_bind,  " )" )
	print(query_template)
	var _success = db.query_with_bindings( query_template, vals );
	
	db.close_db()


func database_to_game(thing:Object, tablekey_propval:Dictionary, target_db_path:String, \
target_table_name:String, query_conditions:String ):
	var row_dict : Dictionary = {}
	var selected_columns : Array = tablekey_propval.keys()
	
	db = SQLite.new()
	db.path = target_db_path
	db.open_db()
	
	var fetched:Array = db.select_rows( target_table_name, query_conditions, selected_columns )
	if fetched.size() == 0:
		return null
	
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
						thing.set(tablekey_propval[key]["property"], db_unwrap(fetched.front()[ key ]) )
					else:
						# thing.set(property[index] <-- fetched[key])
						thing.set(tablekey_propval[key]["property"] [tablekey_propval[key]["index"]], db_unwrap(fetched.front()[ key ]))
				else:
					# thing.set(property <-- fetched[key])
					thing.set(tablekey_propval[key]["property"], db_unwrap(fetched.front()[ key ]))
	db.close_db()
	return thing


# To be called by GlobalMonsterSpawner
func store_monster( monster ):
	game_to_database( monster, tkpv_monster, DB_PATH_USER_ACTIVE, table_name_monster, \
	str("UMID = ", monster.umid) )


func save_monster( monster ):
	if( exists_monster( monster ) ):
		update_monster( monster )
	else:
		store_monster( monster )


# Contains code to save monster character to database
func update_monster( monster ):
	database_to_game( monster, tkpv_monster, DB_PATH_USER_ACTIVE, table_name_monster, \
	str("UMID = ", monster.umid) )


func save_gamepiece( gamepiece:Gamepiece ):
	var umid = gamepiece.umid
	game_to_database(gamepiece, tkpv_gamepiece, DB_PATH_USER_ACTIVE, "gamepiece", str(" UMID = ", umid )  )
	game_to_database(gamepiece.monster, tkpv_monster, DB_PATH_USER_ACTIVE, "monster", str(" UMID = ", umid )  )


func load_gamepiece( umid:int ) -> Gamepiece:
	var gamepiece = Gamepiece.new()
	gamepiece.monster = Monster.new()
	gamepiece.umid = umid
	database_to_game(gamepiece, tkpv_gamepiece, DB_PATH_USER_ACTIVE, "gamepiece", str(" UMID = ", umid ) )
	database_to_game(gamepiece.monster, tkpv_monster, DB_PATH_USER_ACTIVE, "monster", str(" UMID = ", umid ) )
	return gamepiece


func update_gamepiece( gamepiece:Gamepiece ) -> Gamepiece:
	database_to_game(gamepiece, tkpv_gamepiece, DB_PATH_USER_ACTIVE, "gamepiece", str(" UMID = ", gamepiece.umid ) )
	database_to_game(gamepiece.monster, tkpv_monster, DB_PATH_USER_ACTIVE, "monster", str(" UMID = ", gamepiece.umid ) )
	return gamepiece


func load_gamepieces_for_map( map_id ) -> Array[Gamepiece]:
	var selected_columns : Array = ["umid", "current_position", 
									"current_direction", "current_action"];
	
	db = SQLite.new()
	db.path = DB_PATH_USER_ACTIVE
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


"""
	Returns a list of all matching monsters.
	Realistically, you only need the first entry, so use [0] or pop_front.
"""
func fetch_dex_from_index(species:int, row_array:Array[String]=["tag"]) -> Array:
	db = SQLite.new()
	db.path = DB_PATH_PATCH_TEMPLATE
	db.open_db()
	
	var query_result = db.select_rows( table_name_species, str("species_ID = ", species), row_array );
	db.close_db()
	return query_result


# Does not use game_to_database because GtDB is for objects and looks iffy.
# This is smaller, and probably more stable, at the small cost of overall code expansion.
func save_keyval(_key:String, _val):
	_key = cheap_sanitize(_key)
	
	db = SQLite.new()
	db.path = DB_PATH_USER_ACTIVE
	db.open_db()
	var query_template = str( "INSERT OR REPLACE INTO ", table_name_keyval, " ( key, value ) " )
	query_template = str(query_template, " values ( ?, ? )" )
	print(query_template)
	var _success = db.query_with_bindings( query_template, [ _key, db_wrap(_val)] );
	
	db.close_db()


func load_keyval(_key:String, _val=null):
	_key = cheap_sanitize(_key)
	
	db = SQLite.new()
	db.path = DB_PATH_USER_ACTIVE
	db.open_db()
	
	var query_conditions = str("key = '", _key, "'") 
	var fetched:Array = db.select_rows( table_name_keyval, query_conditions, ["key", "value"] )
	db.close_db()
	
	if fetched.size() > 0:
		_val = fetched.front()["value"]
	return _val


# Used for save/load_keyval, to avoid escaping strings too early
func cheap_sanitize( statement:String ):
	statement = statement.replace(")", "")
	statement = statement.replace("(", "")
	statement = statement.replace("'", "")
	statement = statement.replace('"', "")
	statement = statement.replace(';', "")
	statement = statement.replace('/', "//")
	statement = statement.replace('\\', "/")
	return statement


# Saves the gametoken & graph connection data
func save_map_link_data():
	pass


# Retrieves the gametoken & graph connection data
func load_map_link_data():
	pass


func load_level_map( map:int ):
	var dummy_map := LevelMap.new()
	dummy_map.map_index = (map as GlobalGamepieceTransfer.MapIndex)
	return database_to_game(dummy_map, tkpv_level_map, DB_PATH_USER_ACTIVE, "level_map", str("map_id = ", map) )


# Saves which file path correlates to the level map index
func save_level_map( map:LevelMap ):
	game_to_database(map, tkpv_level_map, DB_PATH_USER_ACTIVE, "level_map", str("map_id = ", map.map_index) )
	pass


# Predicts the ability to recover the previous state based on:
# 1: Does the player exist? (code may change to account for non-zero UMID)
# 2: Does the player exist in a valid map?
# 3: Does the valid map have a known file path?
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


func reset_save_file() -> void:
	var db_reset = SQLite.new(); db_reset.path = DB_PATH_USER_TEMPLATE; db_reset.open_db()
	#var db_commit = SQLite.new(); db_commit.path = DB_PATH_USER_COMMIT; db_commit.open_db()
	
	var globalized_active_path = ProjectSettings.globalize_path(DB_PATH_USER_ACTIVE) + ".db"
	var globalized_commit_path = ProjectSettings.globalize_path(DB_PATH_USER_COMMIT) + ".db"
	
	if FileAccess.file_exists( DB_PATH_USER_COMMIT + ".db" ):
		OS.move_to_trash( globalized_commit_path )
	if FileAccess.file_exists( DB_PATH_USER_ACTIVE + ".db" ):
		OS.move_to_trash( globalized_active_path )
	
	db_reset.query("VACUUM INTO \"" + globalized_commit_path + "\"")
	db_reset.query("VACUUM INTO \"" + globalized_active_path + "\"")
	
	db_reset.close_db()
	
	var config = ConfigFile.new()
	var rand_hex = Crypto.new().generate_random_bytes(4).hex_encode()
	config.load(CONFIG_FILE_PATH)
	config.set_value("save", "current", rand_hex)
	if config.has_section(rand_hex):
		config.erase_section(rand_hex) ## In case of random number collision
	config.set_value(rand_hex, "player_umid", 0)
	config.save(CONFIG_FILE_PATH)


func _regenerate_user_database_folder():
	## Ensures there is a 'database' folder in the user save file
	var directory_check = DirAccess.open("user://database")
	if directory_check == null:
		directory_check = DirAccess.get_open_error() 
		## ^ Supposed to check to see if file can be made, but why bother?
		DirAccess.make_dir_absolute("user://database")
	
	## If there is no config file, make it.
	var config_file = FileAccess.file_exists(CONFIG_FILE_PATH)
	if config_file == null:
		config_file = ConfigFile.new()
		config_file.save(CONFIG_FILE_PATH)
	
	## Ensures there is a 'patchdata' database in the user save file
	var patchdata_check = FileAccess.file_exists(DB_PATH_PATCH_USER)
	if patchdata_check == false:
		var db_patch = SQLite.new(); db_patch.path = DB_PATH_PATCH_TEMPLATE; db_patch.open_db()
		var globalized_patch_path = ProjectSettings.globalize_path(DB_PATH_PATCH_USER) + ".db"
		db_patch.query("VACUUM INTO \"" + globalized_patch_path + "\"")
		db_patch.close_db()
	pass


func does_save_exist() -> bool:
	return FileAccess.file_exists(str(DB_PATH_USER_ACTIVE, ".db"))


# Loads the player, and the last map the player was known to be in, and returns the map path
# In the future, may also update the in-game clock settings and trickle down save data
func recover_last_state() -> String:
	var gp_read : Gamepiece = load_gamepiece( 0 )
	if gp_read == null:
		return ""
	var map_player = load_level_map( gp_read.current_map )
	if map_player == null:
		return ""
	
	GlobalRuntime.scene_manager.append_preload_map( map_player.scene_file_path )
	while !GlobalRuntime.scene_manager.map_is_ready( map_player.scene_file_path ):
		await get_tree().process_frame
		await get_tree().process_frame
	GlobalRuntime.scene_manager.change_map_from_path( map_player.scene_file_path )
	
	var overworld = GlobalRuntime.scene_manager.get_overworld_root() as LevelMap
	var gp_model := load("res://player/player.tscn")
	var gp_player : Gamepiece = gp_model.instantiate()
	gp_player.transfer_data_from_gp(gp_read)
	gp_player.current_position = gp_player.current_position
	await overworld.place_gamepieces( [gp_player] )
	gp_player.visible = true
	gp_player.unique_id = 0
	#gp_player.my_camera.tween_resource.duration = 0#my_camera.reset_smoothing()
	for child in gp_player.get_children():
		if child is Node2D:
			child.visible = true
	
	load_global_data() # Should recover background stuff like Gamepieces, their AI, Gametokens, etc
	
	return map_player.scene_file_path


##TODO: Refactor current save system to use this (currently empty) function
# Saves data stored in Global/Autoload classes, like in-game time/date, etc
func save_global_data():
	pass


##TODO: Expand current load/"recover" system to use this (currently empty) function
# Loads stored data into Global/Autoload classes, like in-game time/date, etc
func load_global_data():
	pass


func fetch_save_to_stage():
	var db_commit = SQLite.new(); db_commit.path = DB_PATH_USER_COMMIT; db_commit.open_db()
	var db_backup = SQLite.new(); db_backup.path = DB_PATH_USER_BACKUP; db_backup.open_db()
	
	var success
	
	#var globalized_backup_path = ProjectSettings.globalize_path(DB_PATH_USER_BACKUP) + ".db"
	#var globalized_commit_path = ProjectSettings.globalize_path(DB_PATH_USER_COMMIT) + ".db"
	var globalized_stage_path = ProjectSettings.globalize_path(DB_PATH_USER_ACTIVE) + ".db"
	
	if FileAccess.file_exists( DB_PATH_USER_ACTIVE + ".db" ):
		OS.move_to_trash( globalized_stage_path )
	
	success = db_commit.query("VACUUM INTO \"" + globalized_stage_path + "\"")
	
	if !success:
		success = db_backup.query("VACUUM INTO \"" + globalized_stage_path + "\"")
		
		if !success:
			print("It seems your journal is damaged... How far can you go without saving?")
		print("Your journal latch seems stuck... We'll just have to see what you remember!")
	print("Your journal opened wide! Your past adventures are still here, bless the Stars.")
	
	db_commit.close_db()
	db_backup.close_db()


func commit_save_from_active() -> bool:
	var db_active = SQLite.new(); db_active.path = DB_PATH_USER_ACTIVE; db_active.open_db()
	var db_commit = SQLite.new(); db_commit.path = DB_PATH_USER_COMMIT; db_commit.open_db()
	
	var globalized_backup_path = ProjectSettings.globalize_path(DB_PATH_USER_BACKUP) + ".db"
	var globalized_commit_path = ProjectSettings.globalize_path(DB_PATH_USER_COMMIT) + ".db"
	
	var success : bool
	
	if FileAccess.file_exists( DB_PATH_USER_BACKUP + ".db" ):
		OS.move_to_trash( globalized_backup_path )
		print("db backup trashed")
	else:
		print("db backup not trashed // ", DB_PATH_USER_BACKUP, " ", globalized_backup_path)
	
	success = db_commit.query("VACUUM INTO \"" + globalized_backup_path + "\"")
	
	db_commit.close_db()
	# If the VACUUM INTO Backup did not work, then DO NOT then delete the Commit version.
	# This is why we have three copies, so we can delete one and still be able to recover.
	if success:
		print("commit => backup succeeded")
		if FileAccess.file_exists(DB_PATH_USER_COMMIT + ".db" ):
			OS.move_to_trash( globalized_commit_path )
			print("db commit trashed")
		else:
			print("db commit not trashed //")
		
		success = db_active.query("VACUUM INTO \"" + globalized_commit_path + "\"")
		
		if success:
			print("stage => commit succeeded")
		else:
			print("stage => commit failed")
	else:
		print("commit => backup failed")
		
	
	db_active.close_db()
	
	return success


func is_gamepiece_player(gamepiece:Gamepiece):
	var config = ConfigFile.new(); config.load(CONFIG_FILE_PATH)
	var player_umid = config.get_value( config.get_value("save", "current"), "player_umid" )
	
	return gamepiece.umid == str(player_umid).to_int()


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

func load_inventory( umid:int=0, compartment:int=-1 ) -> Array:
	
	## Create database variable, open it for the user save data.
	db = SQLite.new()
	db.path = DB_PATH_USER_ACTIVE
	db.open_db()
	
	## Get all items listed for the selected user, then close the database.
	var query_conditions : String = str("umid = '", umid, "'") 
	var fetched:Array = db.select_rows( "inventory", query_conditions, ["item", "quantity"] )
	db.close_db()
	
	## Using the same database interface, open Patch Data
	db.path = DB_PATH_PATCH_USER
	db.open_db()
	
	## If the compartment number is valid, cull irrelevant entries from the list of available items
	if compartment >= 0 and compartment < Inventory.Categories.MAX:
		query_conditions = str("bag_slot = '", compartment, "'") 
	else:
		query_conditions = "true"
	var item_templates:Array = db.select_rows( "item", query_conditions, 
			["id", "tr_key", "sprite", "tr_key_detail", "stack_size"] )
	db.close_db()
	
	## Reformat the item templates from Patch Data to be easier to iterate through
	var templates := {}
	for item in item_templates:
		templates[ item["id"] ] = { 
			"tr_key" : item["tr_key"],
			"tr_key_detail" : item["tr_key_detail"],
			"sprite_path" : item["sprite"],
			"stack_size" : item["stack_size"]
		}
	
	var filtered = []
	
	## If the fetched row has an item in the appropriate bag slot, give it the translation key and
	## prepare to submit it to the function caller.
	for row in fetched:
		if row["item"] in templates.keys():
			var item = templates[row["item"]]
			row["tr_key"] = item["tr_key"]
			row["tr_key_detail"] = item["tr_key_detail"]
			row["sprite_path"] = item["sprite_path"]
			row["stack_size"] = item["stack_size"]
			filtered.append(row)
	
	return filtered
