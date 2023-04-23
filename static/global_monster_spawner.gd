extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Checks database for monster. If not found, create a new one.
# MAKE SURE TO STORE IVs AND EVs IN THE DATABASE BEFORE HANDING BACK THE MONSTER IF THESE ARE NOT STORED WITHIN THE MONSTER
func spawn_monster( seed: int, spawn_weights: Dictionary ) -> Object:
	return null
	pass
