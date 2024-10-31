extends Node2D
class_name SceneManager 

# Structure is "FilePath" : [ packed scene, Time to live ]
var scenes_ready : Dictionary
var scenes_waiting : Array
@onready var gamepiece_nav_map : RID = get_world_2d().get_navigation_map()

@onready var activity_interface_wrapper = $InterfaceActivityWrapper
@onready var activity_interface = $InterfaceActivityWrapper/InterfaceActivity
@onready var world_interface = $PlayerCamView/SubViewport/InterfaceWorld
@onready var screen_transition = $ScreenTransition
@onready var player_menu = $Menu

# Keep the -1, it's a mnemonic.
# The number preceding the '-1' is the number of levels you can access before an item expires.
const TTL_RESET := 4 - 1

enum InterfaceOptions
{
	WORLD, # For the Overworld
	ACTIVITY # For more complex menus, as well as games
}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	var i := 0
	while i < scenes_waiting.size():
		match ResourceLoader.load_threaded_get_status( scenes_waiting[i] ):
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED:
				scenes_waiting.remove_at(i)
				pass
			ResourceLoader.THREAD_LOAD_LOADED:
				scenes_ready[ scenes_waiting[i] ] = [ResourceLoader.load_threaded_get( scenes_waiting[i] ).instantiate(), TTL_RESET]
				scenes_waiting.remove_at(i)
				pass
		
	pass


func map_rid_for_gamepiece(_gamepiece:Gamepiece):
	return gamepiece_nav_map


func switch_to_interface( interface:InterfaceOptions ):
	match interface:
		InterfaceOptions.ACTIVITY:
			world_interface.process_mode = Node.PROCESS_MODE_DISABLED
			activity_interface_wrapper.process_mode = Node.PROCESS_MODE_INHERIT
			activity_interface_wrapper.scale = Vector2(1,1)
			activity_interface_wrapper.position = Vector2(0,0)
			activity_interface_wrapper.visible = true
			pass
		_: # Default:
			world_interface.process_mode = Node.PROCESS_MODE_INHERIT
			activity_interface_wrapper.process_mode = Node.PROCESS_MODE_DISABLED
			activity_interface_wrapper.scale = Vector2(0.001,0.001)
			activity_interface_wrapper.position = Vector2(-2048,-2048)
			activity_interface_wrapper.visible = false
			pass
	pass


func get_map_index( map:String ) -> int:
	if scenes_ready.has(map):
		return scenes_ready[map][0].map_index
	return -1


func change_map_from_path( map:String ) -> int:
	var next_map;
	
	if scenes_ready.has(map):
		# This following line of code caused a lot of errors in the debugger. Was fixed?
		next_map = scenes_ready[map][0]
		scenes_ready.erase( map )
	elif map.is_valid_filename():
		next_map = load( map )#.new()
	else:
		append_preload_map( map )
		return -1
	change_map( next_map )
	return 0


func change_map( map_template ):
	var old_children = world_interface.get_children()
	var next_map
	
	if map_template is PackedScene:
		next_map = map_template.instantiate()
	else:
		next_map = map_template#.new()
		
	for child in old_children:
		if child is LevelMap:
			child.pack_up()
		GlobalRuntime.clean_up_node_descent( child )
	
	world_interface.add_child( next_map ) #.instantiate()
	pass


func map_is_ready( map:String ):
	return scenes_ready.has(map)


func append_preload_map( map:String ):
	if !scenes_ready.has(map):
		if map.length() > 0:
			ResourceLoader.load_threaded_request(map)
			scenes_waiting.append(map)
	else:
		scenes_ready[map][1] = TTL_RESET;


func get_overworld_root():
	var children = world_interface.get_children()
	
	# Because I am lazy and prefer crashing from memleaks than crashing from null pointers.
	if children == null or children.size() < 1:
		world_interface.add_child( Node2D.new() )
	
	return world_interface.get_children().back()


func mount_cinematic( cine:Control ):
	
	# I assume this works as a check for if the cine & scene manager co-exist
	if not cine.is_inside_tree():
		activity_interface.add_child( cine )
	switch_to_interface( SceneManager.InterfaceOptions.ACTIVITY )
	await (cine as Cinematic).cinematic_finished
	for child in activity_interface.get_children():
		child.queue_free()
	switch_to_interface( SceneManager.InterfaceOptions.WORLD )
	pass




func update_preload_portals( ttl_decrement : int = 1 ):
	var portals = get_tree().get_nodes_in_group("portals")
	
	# Whatever resources are not yet available, queue loading
	for portal in portals:
		if !scenes_ready.has(portal.map):
			if portal.map.length() > 0:
				ResourceLoader.load_threaded_request(portal.map)
				scenes_waiting.append(portal.map)
		else:
			scenes_ready[portal.map][1] = TTL_RESET;
		pass
	
	# Whatever resources have not been updated, decrement their TTL
	for rs in scenes_ready.keys():
		scenes_ready[rs][1] = scenes_ready[rs][1] - abs(ttl_decrement);
		
		# If their TTL is expired, remove from the list
		if scenes_ready[rs][1] < 0:
			if scenes_ready[rs][0] is LevelMap:
				await GlobalGamepieceTransfer.save_map_gamepieces( scenes_ready[rs][0] )
			GlobalRuntime.clean_up_node_descent( scenes_ready[rs][0] )
			scenes_ready.erase(rs)
	pass


func fade_to_black( duration:=0.25 ) -> bool:
	screen_transition.visible = true
	var blackness = $ScreenTransition/Darkness #ColorRect.new()
	#blackness.set_anchors_preset( Control.LayoutPreset.PRESET_FULL_RECT )
	blackness.color = Color.BLACK
	blackness.visible = true
	var new_modulate = Color.WHITE
	new_modulate.a = 0
	blackness.modulate = new_modulate
	#screen_transition.add_child( blackness )
	
	print("darkness color +> ", blackness.color, blackness.modulate)
	var move_tween = create_tween()
	if move_tween != null:
		move_tween.tween_property(blackness, "modulate", \
			Color(0,0,0,1) , duration ).set_trans(Tween.TRANS_LINEAR)
		await move_tween.finished
	print("darkness color ++> ", blackness.color, blackness.modulate)
	
	return true


func fade_in( duration:=0.75 ):
	var blackness = $ScreenTransition/Darkness #ColorRect.new()
	#blackness.set_anchors_preset( Control.LayoutPreset.PRESET_FULL_RECT )
	#blackness.color = Color.BLACK
	blackness.visible = true
	#blackness.modulate = Color.BLACK
	#screen_transition.add_child( blackness )
	
	print("darkness color +> ", blackness.color, blackness.modulate)
	var move_tween = create_tween()
	if move_tween != null:
		move_tween.tween_property(blackness, "modulate", \
			Color.TRANSPARENT, duration ).set_trans(Tween.TRANS_LINEAR)
		await move_tween.finished
	print("darkness color ++> ", blackness.color, blackness.modulate)
	pass
