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
	
	var y_sort : Node = null
	
	# If the Objects node doesn't exist, make it.
	if get_node_or_null( ^"Objects" ) == null:
		var object_folder = Node.new()
		object_folder.name = "Objects"
		add_child( object_folder )
	else:
		y_sort = get_node_or_null( ^"Objects/Y-Sort" )
	
	# If the Y-Sort node doesn't exist, make it.
	if y_sort == null:
		var ysort_folder = Node.new()
		ysort_folder.name = "Y-Sort"
		get_node_or_null( ^"Objects" ).add_child( ysort_folder )
	
	# Now that the Y-Sort is almost guaranteed to exist, put any characters in there.
	# BUT JUST IN CASE, keep using the "get_node_or_null" and keep track of the null errors.
	for piece in gamepieces:
		get_node_or_null( ^"Objects/Y-Sort" ).add_child(piece)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func populate_with_gamepieces():
	var gamepieces = GlobalGamepieceTransfer.eject_gamepieces_for_map(map_index)
	for piece in gamepieces:
		add_child(piece)
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
