extends Node
# Most of this stuff oughta be static methods.

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


var effect_struct : Dictionary = {
	"effect" = 0,
	"hit_chance" = 0,
}


enum TargetFlags
{
	HAS_SPECIAL_TARGETING,	# Does not abide by the other flags necessarily...
	CAN_TARGET_ALLIES,		# Can this be applied to your team?
	CAN_TARGET_ENEMIES,		# Can this be applied to your opponents?
	CAN_TARGET_SELF,		# Can you chose whether you are affected?
	AFFECTS_ALL_ALLIES,		# Auto-selects all teammates.
	AFFECTS_ALL_ENEMIES,	# Auto-selects all enemies.
	AFFECTS_USER,			# Auto-selects user
	CAN_MULTI_TARGET,		# Can this be applied to multiple combatants?
	CAN_SELECT_TARGET,		# Can you specify who is/isnt affected?
	HAS_EXTENDED_RANGE,		# Can you reach everyone in a 3v3?
}
# Interesting combinations: affects_all_enemies but not can_target_enemies.

enum BooleanFlags
{
	MAKES_CONTACT,		# Would this technique cause the combattants to touch eachother?
	IS_PROTECTABLE,		# Would making a shield stop the effects?
	IS_REFLECTABLE,		# Can it be parried via visual reflection or a bat swing?
	IS_SNATCHABLE,		# Is it a status technique that can be interruped and used by another?
	IS_REPLICABLE,		# Can it be performed by anyone with the right spirit?
	IS_FLINCHABLE,		# Is there a chance for hesitation upon seeing royalty?
	IS_SOUND_BASED,		# Is sound the carrier of, or basis for, the intended effect?
	IS_MOUTH_BASED,		# Would a muzzle prevent the intended effect?
	IS_POWDER_BASED,	# Is a fine dust the basis for the intended effect?
	IS_PUNCH_BASED,		# Are fists the carrier of, or basis for, the intended effect?
	IS_BITE_BASED,		# Are teeth the carrier of, or basis for, the intended effect?
	IS_AURA_BASED,		# Does it come from the soul's energy or fighting force?
	IS_EXPLOSION_BASED,	# Is this technique itself an explosion or cause the user to explode?
	IS_DANCE_BASED,		# Is dancing the carrier of, or basis for, the intended effect?
	IS_PROJECTILE_BASED,	# Would being bulletproof make this technique useless?
	IS_SLICE_BASED,		# Is a cutting edge the basis for the intended effect?
}

# 2 tier key-value pairing: attacker, defender, multiplier
static var type_matchup = {}

var techniques_loaded = {}

var secondary_techniqueeffect_template = {
	"techniqueeffect" = null,
	"type_one" = null,
	"type_two" = null,
	"accuracy" = 0,
	"flag_bitfield" = 0,
	"flag_target" = 0,
	"accuracy_dependence" = false	# true = only executes if primary effect executes
}

# base_power, accuracy, primary_effect, flag_bitfield, 
# effects, effect_accuracies, type1, type2, priority, cost
var default_move = Technique.new(100, 100, null, 0, [], [], 0, 0)




# Index = "similarity value" ~= index matchup counted in a roundabout way
# Higher value = better. Max as of this comment is 6 in theory, but should be unreachable normally
# This system may be replaced in a future version.
static var stab_multiplier = [1, 1.25, 1.5, 1.5, 1.5, 2, 2.25]

func load_technique_from_database( _move_reference ):
	pass
	# Calls database, links effect shorthand/index to effect objects and passes to the manager.


func preprocess_ability_effects( _user, _target, _move, _raw_damage, _tags:={}) -> Dictionary:
	
	return _tags


func preprocess_item_effects( _user, _target, _move, _raw_damage, _tags:={}) -> Dictionary:
	
	return _tags


func execute_technique( _move:Technique, _users:Array[Combatant], _targets:Array[Combatant] ):
	
	var raw_damage := 0.0
	var tags := {}
	
	for user in _users:
		for target in _targets:
			@warning_ignore("static_called_on_instance")
			raw_damage = GlobalTechnique.calculate_raw_damage( [_move.type_one, _move.type_two], user, target )
			
			tags = {"raw_damage":raw_damage}
			
			tags = preprocess_ability_effects( user, target, _move, raw_damage, tags )
			#tags = preprocess_ability_effects( user, target, move, raw_damage, tags )
			
			tags = preprocess_item_effects( user, target, _move, raw_damage, tags )
			#tags = preprocess_item_effects( user, target, move, raw_damage, tags )
	
	pass
	# Intakes user, array of targets, effects, tags and flags. Calculates changes via effect code, synthesizes and cleans results, then applies changes to the combatants.


# Not raw as in 'completely unedited', but as in 'before Effects are applied'.
static func calculate_raw_damage( technique, user, target ) -> float: 
	var type_damage = type_matchup[ technique.type1 ][ target.type1 ] * type_matchup[ technique.type1 ][ target.type2 ] + ( type_matchup[ technique.type2 ][ target.type1 ] + type_matchup[ technique.type2 ][ target.type2 ] + 1 ) / 3;
	var stab_level = calculate_stab_level( technique, user );
	return type_damage * stab_multiplier[stab_level] * technique.base_power


static func calculate_type_effectiveness( action, target ) -> float:
	return type_matchup[action.type1][target.type1] * type_matchup[action.type1][target.type2] \
	+ ( type_matchup[action.type2][target.type1] + type_matchup[action.type2][target.type2] + 1)/3;


static func calculate_stab_level( technique, user ) -> int:
	var stab_level = 0;
	
	if (technique.type1 == user.type1):
		stab_level += 3
	if (technique.type2 == user.type1 || technique.type1 == user.type2):
		stab_level += 2
	if (technique.type2 == user.type2):
		stab_level += 1
	
	return stab_level
