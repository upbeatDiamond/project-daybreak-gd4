extends Node2D
class_name LevelMap

# Has to be -1 or a unique positive number
@export var unique_id := -1			# not currently used, but do not remove yet
const Y_SORT_FOLDER_NAME:="Y-Sort"

# linked to the gamepiece transfer class
@export var map_index := ( -1 as GlobalGamepieceTransfer.MapIndex ) 
var current_gamepieces:=[Gamepiece]

var debug_please_remove:=[1,3,2]

# Called when the node enters the scene tree for the first time.
func _ready():
	
	if GlobalRuntime.scene_manager != null:
		GlobalRuntime.scene_manager.update_preload_portals()
		establish_ysort()
		rehouse_gamepieces()
		populate_with_gamepieces()
	print(debug_please_remove[1], get("debug_please_remove[1]"))
	print("Hoi! It's me! A Level Map!!!!")
	pass


func establish_ysort():
	# If the Objects node doesn't exist, make it.
	if get_node_or_null( ^"Objects" ) == null:
		var object_folder = Node.new()
		object_folder.name = "Objects"
		add_child( object_folder )
	
	var y_sort : Node  = get_node_or_null( ^"Objects/Y-Sort" )
	# If the Y-Sort node doesn't exist, make it.
	if y_sort == null:
		var ysort_folder = Node.new()
		ysort_folder.name = Y_SORT_FOLDER_NAME
		get_node_or_null( ^"Objects" ).add_child( ysort_folder )


func rehouse_gamepieces():
	var children = get_children()
	for child in children:
		if not(child is Gamepiece):
			children.append_array( child.get_children() )
		else:
			# please please don't make another node called 'Y-Sort', please.
			child.reparent( find_child(Y_SORT_FOLDER_NAME, true) )
			(child as Gamepiece).current_map = map_index
			current_gamepieces.append(child)
	pass


func place_gamepieces( gamepieces:Array ):
	establish_ysort()
	var ysort = get_node_or_null( ^"Objects/Y-Sort" )
	#var is_dirty:bool
	
	# Now that the Y-Sort is almost guaranteed to exist, put any characters in there.
	# BUT JUST IN CASE, keep using the "get_node_or_null" and keep track of the null errors.
	for piece in gamepieces:
		piece.current_map = map_index
		#is_dirty = false
		for old_piece in current_gamepieces:
			if (old_piece is Gamepiece) and (piece is Gamepiece) and (piece.monster != null)\
			and piece.monster.equals( old_piece.monster ):
				#is_dirty = true
				if old_piece != null:
					(old_piece as Node).get_parent().remove_child(old_piece)
					GlobalRuntime.clean_up_node_descent( old_piece )
					current_gamepieces.remove_at( current_gamepieces.find(old_piece) )
		
		current_gamepieces.append(piece)
		
		ysort.add_child(piece)
		piece.add_to_group("gamepiece")
		
		piece.global_position = piece.current_position
		print("placing gamepiece at co-ord ~ ", piece.global_position, piece.current_position)
	return 0



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#print(get_anchor_container())
	pass



func populate_with_gamepieces():
	var gamepieces = GlobalGamepieceTransfer.eject_gamepieces_for_map(map_index)
	#for piece in gamepieces:
	#	add_child(piece)
	
	place_gamepieces( gamepieces )
	pass


func get_anchor_container():
	var anchor_container = find_child("Anchors", false)
	return anchor_container


func pack_up():
	var childs = get_children()
	
	# Tagged out to avoid massive duplication of the test NPC. Now only clones the Player.
	# Recursively find & pack up gamepieces, assuming no gamepieces have gamepiece children
	# Please replace this with a signal.
	# EDIT TO ABOVE COMMENTS: Untagged out to see what happens. Doesn't break yet but... eh....????
	
	GlobalGamepieceTransfer.save_map_gamepieces( self )
	
	for child in childs:
		if child is Gamepiece:
			GlobalGamepieceTransfer.submit_gamepiece(child, map_index, \
				child.global_position, map_index)
		else:
			childs.append_array( child.get_children() )
	
	pass
