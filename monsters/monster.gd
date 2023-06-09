extends Node
class_name Monster

# Called when the node enters the scene tree for the first time.
func _init():
	p_factor_base.resize( GlobalMonster.PersonalityFactor.size() );
	p_factor_offset.resize( GlobalMonster.PersonalityFactor.size() );
	moves_active.resize( GlobalMonster.max_battle_moves );
	stats_base.resize( GlobalMonster.BattleStats.size() );
	stats_current.resize( GlobalMonster.BattleStats.size() );
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Used for proper saving/loading/reloading
var umid = -1

@export var level := -1
	# Used to track what moves should be accessible at this point, and is used in same places as stat increases and Evo checks

@export var exp := -1
	# Used to track experience points, which reset upon levelling up

var species := -1
	# Either reference ID for species base info, or storage of summary 

var ability = ""
	# Either reference ID for ability info, or storage of object

var birth_name := ""
@export var nickname := ""

var item_held = ""

var met_at_level = -1


var health: set = set_health, get = get_health;
var spirit: set = set_spirit, get = get_spirit;

# May convert to PackedByteArray or Dictionary
# Represents genetic component to personality
var p_factor_base = PackedByteArray(); 

# May convert to PackedByteArray or Dictionary
# Represents independent personality development
var p_factor_offset = PackedByteArray();

# The moves currently accessible
var moves_learned = {}
var moves_active = []; 

var status_conditions = {}


# The state the stats should be reset to upon healing
# Might be split into IVs, AV/EVs, and Species Strengths
var stats_base = [];


# The stats to be used during battles, stored in array format due to lack of need outside of battle
var stats_current = []; 

# Maps other UMIDs and players onto relationship value arrays
# might contain analogue to Memories
var relationships = {}

# Stores one's special interests
var quirks = {}




func get_current_stat():
	pass

# get current health level
func get_health() -> int:
	var health = stats_current[ GlobalMonster.BattleStats.HEALTH ];
	if (health == null):
		health = 0
	return health

# can turn this into a setget
func set_health( health:int ):
	stats_current[ GlobalMonster.BattleStats.HEALTH ] = health;

# Separated for future damage animations, or abilities
func reduce_health( damage ):
	set_health( get_health() - damage );

# Separated for future healing animations, or abilities
func increase_health( healing ):
	set_health( get_health() + healing );

func change_base_health( change ):
	stats_base[ GlobalMonster.BattleStats.HEALTH ] += change;

# Deprecated due to get_stat, but don't remove yet
func get_spirit() -> int:
	var spirit = stats_current[ GlobalMonster.BattleStats.SPIRIT ];
	if (spirit == null):
		spirit = 0
	return spirit

# can turn this into a setget
func set_spirit( spirit:int ):
	stats_current[ GlobalMonster.BattleStats.HEALTH ] = spirit;

# can turn this into a setget
func get_stat( stat_type:GlobalMonster.BattleStats ):
	var stat = stats_current[ stat_type ]
	if (stat == null):
		stat = 0
	return stat 

# can turn this into a setget
func set_stat( stat_type:GlobalMonster.BattleStats, value:int ):
	stats_current[ stat_type ] = value

func save_data():
	GlobalDatabaseManager.save_monster(self);
	# Write this monster to disk, or to a database, by sending the results of packData to global/singleton

func load_data():
	GlobalDatabaseManager.load_monster(self);
	# Read this monster from disk, or a database, by feeding the results of global/singleton into unpackData

func get_active_moves():
	return moves_active;

func _to_string():
	return str(name, "(", umid, ") is a ", species, " with moves ", moves_learned, " and stats ", stats_base, " -> ", stats_current)

#func saveAndReload:
	# Call saveData and loadData sequentially, possibly setting everything to zero in between

#func unpackData:
	# From a Dict, using the global monster singleton for array size guides, store Dict's values into the proper Variables

#func pack_data() -> Dictionary:

	# Store variable values into a dictionary and return (reference to) resulting structure
