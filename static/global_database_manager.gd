extends Node
# Contains code relating to SQLite bindings


var db : SQLite = null

const verbosity_level : int = SQLite.VERBOSE

var db_name := "res://database/database"

var table_name_monster := "person"
var table_name_player := "person"
#var table_name_relationship := "character"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func exists_monster( monster ) -> bool:
	
	var row_array = ["name"]
	
	db = SQLite.new()
	db.path = db_name
	var query_result = db.select_rows( table_name_monster, str("umid = ", monster.umid), row_array );
	
	if (query_result is Array && query_result.size() > 0):
		return true
	
	return false
	
	pass

# To be called by GlobalMonsterSpawner
func create_monster( monster ):
	
	
	var row_dict : Dictionary = Dictionary()
	#for i in range(0,ids.size()):
	#row_dict["current_health"] = monster.get_current_stat( GlobalMonster.BattleStats.HEALTH ) 
	row_dict["current_health"] = monster.stats_current[GlobalMonster.BattleStats.HEALTH]
	row_dict["current_spirit"] = monster.stats_current[GlobalMonster.BattleStats.SPIRIT]
	row_dict["current_attack"] = monster.stats_current[GlobalMonster.BattleStats.ATTACK]
	row_dict["current_defense"] = monster.stats_current[GlobalMonster.BattleStats.DEFENSE]
	row_dict["current_speed"] = monster.stats_current[GlobalMonster.BattleStats.SPEED]
	row_dict["current_evasion"] = monster.stats_current[GlobalMonster.BattleStats.EVASION]
	row_dict["current_intimidate"] = monster.stats_current[GlobalMonster.BattleStats.INTIMIDATION]
	row_dict["current_resolve"] = monster.stats_current[GlobalMonster.BattleStats.RESOLVE]
	row_dict["current_mana"] = monster.stats_current[GlobalMonster.BattleStats.MANA]
	row_dict["max_health"] = monster.stats_base[GlobalMonster.BattleStats.HEALTH]
	row_dict["max_spirit"] = monster.stats_base[GlobalMonster.BattleStats.SPIRIT]
	row_dict["max_attack"] = monster.stats_base[GlobalMonster.BattleStats.ATTACK]
	row_dict["max_defense"] = monster.stats_base[GlobalMonster.BattleStats.DEFENSE]
	row_dict["max_speed"] = monster.stats_base[GlobalMonster.BattleStats.SPEED]
	row_dict["max_evasion"] = monster.stats_base[GlobalMonster.BattleStats.EVASION]
	row_dict["max_intimidate"] = monster.stats_base[GlobalMonster.BattleStats.INTIMIDATION]
	row_dict["max_resolve"] = monster.stats_base[GlobalMonster.BattleStats.RESOLVE]
	row_dict["max_mana"] = monster.stats_base[GlobalMonster.BattleStats.MANA]
	row_dict["ability"] = monster.ability
	row_dict["exp"] = monster.exp 
	row_dict["level"] = monster.level 
	row_dict["name"] = monster.birth_name 
	row_dict["item_held"] = monster.item_held 
	
	db = SQLite.new()
	db.path = db_name
	
	var query_condition = str("umid = ", monster.umid)
	
	var row_array = [row_dict]
	
	db.insert_rows( table_name_monster, row_array )
	
	pass


func save_monster( monster ):
	if( exists_monster( monster ) ):
		update_monster( monster )
	else:
		create_monster( monster )


# Contains code to save monster character to database
func update_monster( monster ):
	
	var row_dict : Dictionary = Dictionary()
	#for i in range(0,ids.size()):
	row_dict["current_health"] = monster.get_current_stat( GlobalMonster.BattleStats.HEALTH ) 
	row_dict["current_health"] = monster.stats_current[GlobalMonster.BattleStats.HEALTH]
	row_dict["current_spirit"] = monster.stats_current[GlobalMonster.BattleStats.SPIRIT]
	row_dict["current_attack"] = monster.stats_current[GlobalMonster.BattleStats.ATTACK]
	row_dict["current_defense"] = monster.stats_current[GlobalMonster.BattleStats.DEFENSE]
	row_dict["current_speed"] = monster.stats_current[GlobalMonster.BattleStats.SPEED]
	row_dict["current_evasion"] = monster.stats_current[GlobalMonster.BattleStats.EVASION]
	row_dict["current_intimidate"] = monster.stats_current[GlobalMonster.BattleStats.INTIMIDATION]
	row_dict["current_resolve"] = monster.stats_current[GlobalMonster.BattleStats.RESOLVE]
	row_dict["current_mana"] = monster.stats_current[GlobalMonster.BattleStats.MANA]
	row_dict["max_health"] = monster.stats_base[GlobalMonster.BattleStats.HEALTH]
	row_dict["max_spirit"] = monster.stats_base[GlobalMonster.BattleStats.SPIRIT]
	row_dict["max_attack"] = monster.stats_base[GlobalMonster.BattleStats.ATTACK]
	row_dict["max_defense"] = monster.stats_base[GlobalMonster.BattleStats.DEFENSE]
	row_dict["max_speed"] = monster.stats_base[GlobalMonster.BattleStats.SPEED]
	row_dict["max_evasion"] = monster.stats_base[GlobalMonster.BattleStats.EVASION]
	row_dict["max_intimidate"] = monster.stats_base[GlobalMonster.BattleStats.INTIMIDATION]
	row_dict["max_resolve"] = monster.stats_base[GlobalMonster.BattleStats.RESOLVE]
	row_dict["max_mana"] = monster.stats_base[GlobalMonster.BattleStats.MANA]
	row_dict["ability"] = monster.ability
	row_dict["exp"] = monster.exp 
	row_dict["level"] = monster.level 
	row_dict["nam"] = monster.given_name 
	row_dict["item_held"] = monster.item_held 
	
	db = SQLite.new()
	db.path = db_name
	
	var query_condition = str("umid = ", monster.umid)
	
	db.update_rows( table_name_monster, query_condition, row_dict )
	#var insert_query : String = "UPDATE character SET "
	
	
	
	
	#db.query(insert_query);
	
	pass


func save_city():
	pass
	
func save_player():
	pass
	
func save_world():
	pass
	
func load_monster( monster ):
	pass
	
func load_player():
	pass
	
func load_world():
	pass
