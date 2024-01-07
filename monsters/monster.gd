extends Node
class_name Monster

# Used for proper saving/loading/reloading
@export var umid = -1
@export var world_of_origin = -1

	# Used to track what moves should be accessible at this point, ...
	# ... and is used in same places as stat increases and Evo checks
@export var level := -1

	# Used to track experience points, which reset upon levelling up
@export var experience := -1


	# Either reference ID for species base info, or storage of summary 
var species := -1

	# Either reference ID for ability info, or storage of object
var ability = ""


var birth_name := ""
@export var nickname := ""

# The currency level of this monster.
# It should be an int, but floats might be accepted just in case.
#var funds = 0
var keycard = 0

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
var techniques_learned = {}
var techniques_active = []; 

var status_conditions = {}


# The state the stats should be reset to upon healing
# Might be split into IVs, AV/EVs, and Species Strengths
# Called 'max' in the database, in comparison to HP
var stats_base = [];
var stats_growth = [];

# The stats to be used during battles, ...
# ... stored in array format due to lack of need outside of battle
var stats_current = []; 

# Maps other UMIDs and players onto relationship value arrays
# might contain analogue to Memories
var relationships = {}

# Stores one's current endeavors
var activity_heap = {}


# Called when the node enters the scene tree for the first time.
func _init():
	p_factor_base.resize( GlobalMonster.PersonalityFactor.size() );
	p_factor_offset.resize( GlobalMonster.PersonalityFactor.size() );
	techniques_active.resize( GlobalMonster.max_battle_techniques );
	stats_base.resize( GlobalMonster.BattleStats.size() );
	stats_current.resize( GlobalMonster.BattleStats.size() );
	pass # Replace with function body.


func get_current_stat():
	pass

# get current health level
func get_health() -> int:
	var _health = stats_current[ GlobalMonster.BattleStats.HEALTH ];
	if (_health == null):
		_health = 0
	return _health

# can turn this into a setget
func set_health( _health:int ):
	stats_current[ GlobalMonster.BattleStats.HEALTH ] = _health;

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
	var _spirit = stats_current[ GlobalMonster.BattleStats.SPIRIT ];
	if (_spirit == null):
		_spirit = 0
	return _spirit

# can turn this into a setget
func set_spirit( _spirit:int ):
	stats_current[ GlobalMonster.BattleStats.SPIRIT ] = _spirit;

# can turn this into a setget
func get_stat( stat_type:GlobalMonster.BattleStats ):
	var stat = stats_current[ stat_type ]
	if (stat == null):
		stat = 0
	return stat 

# can turn this into a setget
func set_stat( stat_type:GlobalMonster.BattleStats, value:int ):
	stats_current[ stat_type ] = value

# Write this monster to disk, or to a database, ...
# ... by sending the results of packData to global/singleton
func save_data():
	GlobalDatabase.save_monster(self);

# Read this monster from disk, or a database, ...
# ... by feeding the results of global/singleton into unpackData
func load_data():
	GlobalDatabase.load_monster(self);


func get_active_techniques():
	return techniques_active;


func _to_string():
	return str(name, "(", umid, ") is a ", species, " with techniques ", \
	techniques_learned, " and stats ", stats_base, " -> ", stats_current)


func equals(other_mon:Monster) -> bool:
	if other_mon == null:
		return false
	if other_mon.umid == umid && (other_mon.world_of_origin == world_of_origin \
	|| world_of_origin < 0 || other_mon.world_of_origin < 0):
		return true
	return false


#func saveAndReload:
	# Call saveData and loadData sequentially, ... 
	# ... possibly setting everything to zero in between
