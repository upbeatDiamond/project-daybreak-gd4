extends Node

const Matrix = preload("res://common/matrix.gd")
const Monster = preload("res://monsters/monster.gd")

var monster : Monster
var options : Array
var options_weights : Matrix

# Determines overall goal, the win state.
enum OBJECTIVE
{
	FRIENDSHIP,
	PHYSICAL_VICTORY,
	MENTAL_VICTORY,
	ENTERTAINMENT
}

# Determines current battle technique preferences
enum Stance 
{
	HEALER, 	# Prefer boosting ally stats, fall back to defense
	SUPPORT,	# Prefer boosting ally stats, fall back to defense
	TRICKSTER,	# Prefer lowering enemy stats, fall back to boosting ally stats
	SHIELDS,	# Prefer defense, fall back to eliminating largest threat
	BRAWLER,	# Prefer fighting, maximize damage, fall back to stat changes
	PESTER, 	# Prefer targetting special health, else normal health
	MASSAGE,    # Prefer bringing down special defense, else special health
	STALL,		# Stalling? I'm not stalling anything. I'm... stalling? Stalling? You think I'm... stalling.
	SNIPER,		# Prefer fighting, avoiding contact, fall back to defense
	BEFRIEND,	# Prefer showing peace, care, empathy, else do special damage
	TROJAN		# Pseudo-befriending
}

# replace with a matrix when ready
const BATTLE_STANCE_MULTIPLIERS = {
		Stance.HEALER: [0,0],
		
		
	}

enum TargetPriority 
{
	ATTACK_LOWEST_HEALTHPOINTS,
	ATTACK_LOWEST_SPIRITPOINTS,
	ATTACK_LOWEST_HEALTHPERCENT,
	ATTACK_LOWEST_SPIRITPERCENT,
	ATTACK_RANDOM_FOE,
	DEFEND_WEAKEST_ALLY,
	DEFEND_RANDOM_ALLY,
	DEFEND_SELF
}


enum ActionWeights {
	DAMAGE_DEALT,
	KNOCK_OUT_CHANCE,
	SP_DAMAGE_DEALT,
	PSYCHE_OUT_CHANCE,
	ATTACK_VULNERABILITY,
	CHANCE_OF_FIRST_STRIKE,
	TYPE_EFFECTIVENESS,
	SAME_TYPE_ATTACK_BONUS,
	SUCCESS_CHANCE,
	SELF_HEALTH_CHANGE,
	SELF_SP_HEALTH_CHANGE,
	SELF_DEFENSE_CHANGE,
	SELF_SP_DEFENSE_CHANGE,
	SELF_SPEED_CHANGE,
	TARGET_HEALTH_CHANGE,
	TARGET_SP_HEALTH_CHANGE,
	TARGET_DEFENSE_CHANGE,
	TARGET_SP_DEFENSE_CHANGE,
	TARGET_SPEED_CHANGE
}

# Battle role weights for selecting strategy mode
const TARGET_PREF_WEIGHTS = {
		TargetPriority.ATTACK_LOWEST_HEALTHPOINTS  : [],
		TargetPriority.ATTACK_LOWEST_SPIRITPOINTS  : [],
		TargetPriority.ATTACK_LOWEST_HEALTHPERCENT : [],
		TargetPriority.ATTACK_LOWEST_SPIRITPERCENT : [],
		TargetPriority.ATTACK_RANDOM_FOE           : [],
		TargetPriority.DEFEND_WEAKEST_ALLY         : [],
		TargetPriority.DEFEND_RANDOM_ALLY          : [],
		TargetPriority.DEFEND_SELF                 : []
	}




# Emotional trackers
var emotions = {
	affection = 1.0,
	anger = 1.0,
	anxiety = 1.0,
	attentiveness  = 1.0,
	contentment  = 1.0,
	envy  = 1.0,
	guilt  = 1.0,
	joy  = 1.0,
	pride = 1.0
}




var urge_player_alliance; # Desire to join player's team


# Initialize with the 'soul' of a fighter.
func _init(monster:Monster):
	#options = new()
		# Set up options array, so that each row can be multiplied by a Stance vector, 
		# and the columns can be collapsed into an array of option viability.
	self.monster = monster
	
	# For each move, call the database manager for this move's stat array, and merge into matrix.
	
	# JAVA: double dummy_row[ActionWeights.size] // creating a filler row to set/match matrix size
	var dummy_row : Array; dummy_row.resize( ActionWeights.size() )
	var move_weights;
	
	for move in monster.moves_active:
		options.append( move )
		
		# NEED TO REPLACE THIS VARIABLE! Maybe stack the for-each loops? Combinatoric explosion, I know.
		var target
		move_weights = ponder_action_weights(move, target) #GlobalDatabaseManager.load_move_ai_weights(move.id)
		
		# Append dummy row to be overwritten
		options_weights.append[ dummy_row ]
		for weight in ActionWeights:
			options_weights.set_element( options_weights.rows, weight, move_weights[weight] )
		
	
	var quit_row : Array; quit_row.resize( ActionWeights.size() )
	
	


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func plan_next_action():
	
	
	
	pass



func ponder_action_weights(move, target) -> Array :
	var weight_row : Array; weight_row.resize( ActionWeights.size() )
	
	weight_row[ActionWeights.DAMAGE_DEALT] = GlobalMove.calculate_raw_damage(move, monster, target)
	weight_row[ActionWeights.SP_DAMAGE_DEALT] = GlobalMove.calculate_raw_special_damage(move, monster, target)
	weight_row[ActionWeights.SAME_TYPE_ATTACK_BONUS] = GlobalMove.calculate_stab_damage(move, monster, target)
	
	# This needs to be updated eventually
	if (target.health - weight_row[ActionWeights.DAMAGE_DEALT] <= 0):
		weight_row[ActionWeights.KNOCK_OUT_CHANCE] = 100
	else:
		weight_row[ActionWeights.KNOCK_OUT_CHANCE] = 0
	
	# This needs to be updated eventually
	if (target.spirit - weight_row[ActionWeights.SP_DAMAGE_DEALT] <= 0):
		weight_row[ActionWeights.PSYCHE_OUT_CHANCE] = 100
	else:
		weight_row[ActionWeights.PSYCHE_OUT_CHANCE] = 0
	
	# This needs to be updated eventually
	weight_row[ActionWeights.SUCCESS_CHANCE] = move.primary_effect_accuracy
	
	weight_row[ActionWeights.TYPE_EFFECTIVENESS] = GlobalMove.calculate_type_effectiveness(move, target)

	# ATTACK_VULNERABILITY is too hard to calculate right now
	# CHANCE_OF_FIRST_STRIKE is easy to calculate but I don't wanna
	#SELF_HEALTH_CHANGE is too hard to calculate right now
	#SELF_SP_HEALTH_CHANGE is too hard to calculate right now
	#SELF_DEFENSE_CHANGE is too hard to calculate right now
	#SELF_SP_DEFENSE_CHANGE is too hard to calculate right now
	#SELF_SPEED_CHANGE is too hard to calculate right now
	#TARGET_HEALTH_CHANGE would replace DAMAGE_DEALT
	#TARGET_SP_HEALTH_CHANGE would replace SP_DAMAGE_DEALT
	#TARGET_DEFENSE_CHANGE is too hard to calculate right now
	#TARGET_SP_DEFENSE_CHANGE is too hard to calculate right now
	#TARGET_SPEED_CHANGE is too hard to calculate right now
	
	return weight_row

func ponder_safety_level():
	pass

func ponder_next_opponent_moves():
	pass

func ponder_ally_stances():
	pass

func ponder_opponent_stances():
	pass

func ponder_opponent_stats():
	pass
