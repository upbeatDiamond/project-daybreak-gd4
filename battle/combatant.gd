extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

var combatant
	# Stores a Monster, or equivalent

func apply_damage( damage ):
		combatant.reduce_health( damage );
