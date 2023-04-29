extends Node

const Matrix = preload("res://common/matrix.gd")
const Monster = preload("res://monsters/monster.gd")


enum OBJECTIVE
{
	
}

enum BATTLE_ROLE 
{
	HEALER, 	# Prefer boosting ally stats, fall back to defense
	SUPPORT,	# Prefer boosting ally stats, fall back to defense
	TRICKSTER,	# Prefer lowering enemy stats, fall back to boosting ally stats
	SHIELDS,	# Prefer defense, fall back to eliminating largest threat
	BRAWLER,	# Prefer fighting, maximize damage, fall back to stat changes
	SNIPER		# Prefer fighting, avoiding contact, fall back to defense
}

const BATTLE_ROLE_MULTIPLIERS = {
		"Some key name": "value1",
		
		
	}

enum STRATEGY_MODE 
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

# Battle role weights for selecting strategy mode
const STRATEGY_ROLE_WEIGHTS = {
		STRATEGY_MODE.ATTACK_LOWEST_HEALTHPOINTS  : [],
		STRATEGY_MODE.ATTACK_LOWEST_SPIRITPOINTS  : [],
		STRATEGY_MODE.ATTACK_LOWEST_HEALTHPERCENT : [],
		STRATEGY_MODE.ATTACK_LOWEST_SPIRITPERCENT : [],
		STRATEGY_MODE.ATTACK_RANDOM_FOE           : [],
		STRATEGY_MODE.DEFEND_WEAKEST_ALLY         : [],
		STRATEGY_MODE.DEFEND_RANDOM_ALLY          : [],
		STRATEGY_MODE.DEFEND_SELF                 : []
	}

# Emotional trackers
var affection
var anger
var anxiety
var attentiveness 
var contentment 
var envy 
var guilt 
var joy 
var pride



var urge_player_alliance; # Desire to join player's team


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
