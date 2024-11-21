extends Node
class_name BattleTeam

# Supposed to be Array[Combatant], but Godot doesn't like me
var battlers:Array = [null,null,null,null,null,null]


enum FieldPos {
	## The three monsters that can be on the field
	ACTIVE_LEFT,
	ACTIVE_MIDDLE,
	ACTIVE_RIGHT,
	
	## The three monsters that can be swapped in
	BENCH_LEFT,
	BENCH_MIDDLE,
	BENCH_RIGHT,
}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
