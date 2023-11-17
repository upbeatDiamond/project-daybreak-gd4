extends StaticBody2D
# This script is not a Gametoken, because/therefore destruction should be forgiven.

var is_destruction_queued:=false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func run_event( gp:Gamepiece ):
	
	match gp.traversal_mode:
		Gamepiece.TraversalMode.RUNNING, Gamepiece.TraversalMode.BICYCLING:
			is_destruction_queued = true
			pass
		_:
			pass
	
	# run important scripts here, and then kill the grass if queued
	roll_spawn_chance()
	
	if is_destruction_queued:
		self_destruct()
	
	pass

func self_destruct():
	pass

func roll_spawn_chance():
	
	spawn_monster_fight()
	
	pass

func spawn_monster_fight():
	pass
