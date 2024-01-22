extends Area2D
class_name Gametoken

# Intended to be used for items and pushable objects

enum COMPARISON_MODE
{
	EQUALS = 0,
	NOT_EQUALS,
	GREATER_THAN,
	LESSER_THAN,
	XOR,
	AND
}

@export var internal_state : int	# Stores stuff like is_collected or is_planted, etc.
@export var comparison_state : int	# Stores a value to compare to the internal state
@export var comparison_mode := COMPARISON_MODE.EQUALS
@export var token_index : int 		# Stores the token index, allowing for token syncing

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
