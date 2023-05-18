extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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
	MAKES_CONTACT,		# Would this move cause the combattants to touch eachother?
	IS_PROTECTABLE,		# Would making a shield stop the effects?
	IS_REFLECTABLE,		# Can it be parried via visual reflection or a bat swing?
	IS_SNATCHABLE,		# Is it a status move that can be interruped and used by another?
	IS_REPLICABLE,		# Can it be performed by anyone with the right spirit?
	IS_FLINCHABLE,		# Is there a chance for hesitation upon seeing royalty?
	IS_SOUND_BASED,		# Is sound the carrier of, or basis for, the intended effect?
	IS_MOUTH_BASED,		# Would a muzzle prevent the intended effect?
	IS_POWDER_BASED,	# Is a fine dust the basis for, the intended effect?
	IS_PUNCH_BASED,		# Are fists the carrier of, or basis for, the intended effect?
	IS_BITE_BASED,		# Are teeth the carrier of, or basis for, the intended effect?
	IS_AURA_BASED,		# Does it come from the soul's energy or fighting force?
	IS_EXPLOSION_BASED,	# Is this move itself an explosion or cause the user to explode?
	IS_DANCE_BASED,		# Is dancing the carrier of, or basis for, the intended effect?
	IS_PROJECTILE_BASED,	# Would being bulletproof make this move useless?
	IS_SLICE_BASED,		# Is a cutting edge the basis for the intended effect?
}

# 2 tier key-value pairing: attacker, defender, multiplier
var type_matchup = {}

var moves_loaded = {}

var secondary_moveeffect_template = {
	"moveeffect" = null,
	"type_one" = null,
	"type_two" = null,
	"accuracy" = 0,
	"flag_bitfield" = 0,
	"flag_target" = 0,
	"accuracy_dependence" = false	# true = only executes if primary effect executes
}





# Index = "similarity value" ~= index matchup counted in a roundabout way
# Higher value = better. Max as of this comment is 6 in theory, but should be unreachable normally
# This system may be replaced in a future version.
var stab_multiplier = [1, 1.25, 1.5, 1.5, 1.5, 2, 2.25]

func load_move_from_database( move_reference ):
	pass
	# Calls database, links effect shorthand/index to effect objects and passes to the manager.

func execute_move( move, user, target : Array ):
	pass
	# Intakes user, array of targets, effects, tags and flags. Calculates changes via effect code, synthesizes and cleans results, then applies changes to the combatants.

# Not raw as in 'completely unedited', but as in 'before Effects are applied'.
func calculate_raw_damage( move, user, target ) -> float: 
	var type_damage = type_matchup[ move.type1 ][ target.type1 ] * type_matchup[ move.type1 ][ target.type2 ] + ( type_matchup[ move.type2 ][ target.type1 ] + type_matchup[ move.type2 ][ target.type2 ] + 1 ) / 3;
	
	var stab_level = calculate_stab_level( move, user );
	
	return type_damage * stab_multiplier[stab_level] * move.base_power

# Duplicate, please change/edit/replace
func calculate_raw_special_damage( move, user, target ) -> float: 
	var type_damage = calculate_type_effectiveness( move, target )
	var stab_level = calculate_stab_level( move, user );
	return type_damage * stab_multiplier[stab_level] * move.base_power



func calculate_type_effectiveness( move, target ) -> float:
	return type_matchup[ move.type1 ][ target.type1 ] * type_matchup[ move.type1 ][ target.type2 ] + ( type_matchup[ move.type2 ][ target.type1 ] + type_matchup[ move.type2 ][ target.type2 ] + 1 ) / 3;

func calculate_stab_level( move, user ) -> int:
	var stab_level = 0;
	
	if (move.type1 == user.type1):
		stab_level += 3
	if (move.type2 == user.type1 || move.type1 == user.type2):
		stab_level += 2
	if (move.type2 == user.type2):
		stab_level += 1
	
	return stab_level
