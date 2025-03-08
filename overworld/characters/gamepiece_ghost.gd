extends Marker2D

## If a gamepiece doesn't exist yet or is supposed to be in a particular place,
## their ghost can be placed there. Not a spawner (creates new gamepieces), nor
## a forced teleport (in case the corresponding character is in the party).

## Should be used for initial positions of important characters.
## Ignore on repeat visits?


@export var umid := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
