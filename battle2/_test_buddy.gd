extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	var sess = BattleServer.new_battle_dummy();
	sess.start_battle();
	pass # Replace with function body.
