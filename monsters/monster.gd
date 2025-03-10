extends Node
class_name Monster

# Used for proper saving/loading/reloading
@export var umid : int = -1
@export var world_of_origin : int = -1

	# Used to track what moves should be accessible at this point, ...
	# ... and is used in same places as stat increases and Evo checks
@export var level : int = -1

	# Used to track experience points, which reset upon levelling up
@export var experience : int = -1


	# Reference ID for species base info
var species : int = -1

	# Reference ID for ability info
var ability : String = ""


var legal_name := ""
@export var nickname := ""
var color_base_gene1 := GlobalMonster.ColorGene.COMMON
var color_base_gene2 := GlobalMonster.ColorGene.COMMON
var color_accent_gene1 := GlobalMonster.ColorGene.COMMON
var color_accent_gene2 := GlobalMonster.ColorGene.COMMON

# The currency level of this monster, technically.
var reputation : int = 0
var keycard : int = 0

## IV = Individual/Inherent Values
## Generated based on species stats, and modified from there
## To avoid excessive database access, combine with species default values
## Worst case, change in base stats can be attributed to regional differences?
var iv_health : int = 10
var iv_attack : int = 10
var iv_defense : int = 10
var iv_speed : int = 10
var iv_special : int = 10
var iv_spirit : int = 10
var iv_charisma : int = 10
var iv_resolve : int = 10
var iv_evasion : int = 10

## EV = Effort Values
## Increases/decreases based on actions taken
## Separated from IV to allow for EV resetting
var ev_health : int = 10
var ev_attack : int = 10
var ev_defense : int = 10
var ev_speed : int = 10
var ev_special : int = 10
var ev_spirit : int = 10
var ev_charisma : int = 10
var ev_resolve : int = 10
var ev_evasion : int = 10

var current_health : int = 10
var current_spirit : int = 10

# The moves currently accessible
var techniques_active = []; 

var status_conditions = {}


func _init():
	techniques_active.resize( GlobalMonster.MAX_BATTLE_TECHNIQUES );
	pass # Replace with function body.


# get current health level
func get_current_health() -> int:
	#var _health = stats_current[ GlobalMonster.BattleStats.HEALTH ];
	#if (_health == null):
		#_health = 0
	return current_health#_health


# can turn this into a setget
func set_current_health( _health:int ) -> void:
	#stats_current[ GlobalMonster.BattleStats.HEALTH ] = _health;
	current_health = _health


# get default health level
func get_max_health() -> int:
	return ev_health + iv_health


func set_max_health( _max:int ):
	ev_health = _max - iv_health


func tweak_base_health( change:int ):
	ev_health += change


func get_current_spirit() -> int:
	return current_spirit


# can turn this into a setget
func set_spirit( _spirit:int ) -> void:
	current_spirit = _spirit


# get default spirit level
func get_max_spirit() -> int:
	return ev_spirit + iv_spirit


func set_max_spirit( _max:int ) -> void:
	ev_spirit = _max - iv_spirit 


# Write this monster to disk, or to a database, ...
# ... by sending the results of packData to global/singleton
func save_data():
	GlobalDatabase.save_monster(self);

# Read this monster from disk, or a database, ...
# ... by feeding the results of global/singleton into unpackData
func load_data():
	var _load = GlobalDatabase.load_monster(umid);
	var dumb_node =  Node.new() # does nothing, used to compare properties
	for property in _load.get_property_list():
		if property in dumb_node.get_property_list():
			# Skip Node properties, only copy Gamepiece properties
			continue
		self.set( property["name"], _load.get(property["name"]) )


func get_active_techniques():
	return techniques_active;


func _to_string():
	return str(name, "(", umid, ") is a ", species)


func equals(other_mon:Monster) -> bool:
	if other_mon == null:
		return false
	if other_mon.umid == umid && (other_mon.world_of_origin == world_of_origin \
	|| world_of_origin < 0 || other_mon.world_of_origin < 0):
		return true
	return false
