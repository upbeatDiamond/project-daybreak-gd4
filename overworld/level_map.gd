extends Node2D
class_name LevelMap

# Has to be -1 or a unique positive number
@export var unique_id := -1

# linked to the gamepiece transfer class
@export var map_index := ( -1 as GlobalGamepieceTransfer.MapIndex )


# Called when the node enters the scene tree for the first time.
func _ready():
	GlobalRuntime.scene_manager.update_preload_portals()
	var gamepieces = GlobalGamepieceTransfer.eject_gamepieces_for_map(map_index)
	for piece in gamepieces:
		add_child(piece)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func populate_with_gamepieces():
	GlobalGamepieceTransfer.eject_gamepieces_for_map( map_index )
	pass

func pack_up():
	var childs = get_children()
	
	# Tagged out to avoid massive duplication of the test NPC. Now only clones the Player.
#	# Recursively find and pack up gamepieces, assuming that no gamepieces have gamepieces as children
#	for child in childs:
#		if child is Gamepiece:
#			GlobalGamepieceTransfer.submit_gamepiece( child, map_index, child.global_position, map_index )
#		else:
#			childs.append_array( child.get_children() )
	
	pass
