extends Node
class_name GamepieceWalker
# Intended to be a compact version of Gamepiece
# Everything should be the same or smaller, except the ability to walk a graph ...
# ... which is sorta unique, if not an abstraction of its normal traversal methods.

var is_paused = false;	# true if cannot act
var is_moving = false;	# true if walking, running, jumping, etc

@export var monster : Monster

@export var target_map := Vector2(0,0)
@export var current_map := Vector2(0,0)


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
