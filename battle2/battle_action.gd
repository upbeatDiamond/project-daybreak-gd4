extends Node
class_name BattleAction

enum ActionType{
	PASS,	# Do nothing...
	OTHER,	# Do something?
	SWITCH, # move monsters around
	ITEM, # use an item
	MOVE, # use a 'move'
	MEGA, # power up to higher form, probably only a final boss thing
	TALK, # for mid-battle taunts and comments by NPCs
	FLEE, # run, coward!
	REST, # skip turn, recover energy. ironically, depricated (despite being the newest added)
}

enum ActionTarget{
	DISTANT_LEFT,
	DISTANT_MIDDLE,
	DISTANT_RIGHT,
	LOCAL_LEFT,
	LOCAL_MIDDLE,
	LOCAL_RIGHT,
	OTHER	# Sidelines for Switch
}


# Player Turn Actions
var action_priority := {
	ActionType.OTHER : 3,
	ActionType.ITEM : 2,
	ActionType.MOVE : 3,
	ActionType.MEGA : 4,
	ActionType.TALK : 5,
}

# Used to prevent act_type and action_core from overwriting the other
#var _mutex_open := true

var act_type:ActionType = ActionType.PASS

var user:Combatant

var action_core


var targets:Array = []


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _init(_act_type:ActionType, _user:Combatant, _action_core=null, _targets:Array[Combatant]=[]):
	act_type = _act_type
	user = _user
	action_core = _action_core
	targets = _targets
	validate_action_type()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func get_priority():
	if action_priority.has(act_type):
		return action_priority[act_type]
	else:
		return action_priority[ActionType.OTHER]


func validate_action_type():
	match act_type:
		ActionType.MOVE:
			if not action_core is BattleMove:
				action_core = BattleMove.new("missingno")
		_:
			pass
	pass
