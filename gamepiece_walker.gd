extends Node
class_name GamepieceWalker
# Intended to be a compact version of Gamepiece
# Everything should be the same or smaller, except the ability to walk a graph ...
# ... which is sorta unique, if not an abstraction of its normal traversal methods.

# Its name is stupid, I guess it could mean:
#	1) It walks the Gamepiece to its destination
#	2) It walks the graph, and is Gamepiece flavored
#	3) It can take a Monster for a walk, at the behest (or with the branding) of Gamepieces

var is_paused = false;	# true if cannot act
var is_moving = false;	# true if walking, running, jumping, etc

@export var monster : Monster
@export var umid := -1:
	set(_umid):
		umid = _umid
		if monster != null:
			monster.umid = _umid
	get:
		if monster != null:
			return monster.umid
		return umid

@export var target_map : GlobalGamepieceTransfer.MapIndex
@export var target_position : Vector2
@export var current_map : GlobalGamepieceTransfer.MapIndex
@export var current_position : Vector2
# If current_position_is_known, use the Vector2 as where to place the piece.
# Else, use it as a guideline if anything. Don't rely on its value being a valid position.
@export var current_position_is_known := false
@export var controller : Script

func _init( _monster:Monster, 
			_controller:Script,
			_current_map:=GlobalGamepieceTransfer.MapIndex.INVALID_INDEX, 
			_target_map:=current_map,
			_target_position:=Vector2(0,0) ):
	
	monster 		= _monster
	controller 		= _controller
	current_map	 	= _current_map
	target_map 		= _target_map
	target_position = _target_position
	
	pass



# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
