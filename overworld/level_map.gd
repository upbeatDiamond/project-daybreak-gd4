extends Node2D
class_name LevelMap

# Has to be -1 or a unique positive number
@export var unique_id := -1

# linked to the gamepiece transfer class
@export var map_index : GlobalGamepieceTransfer.MapIndex = -1


# Called when the node enters the scene tree for the first time.
func _ready():
	GlobalRuntime.scene_manager.update_preload_portals()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func populate_with_gamepieces():
	GlobalGamepieceTransfer.eject_gamepieces_for_map( map_index )
	pass
