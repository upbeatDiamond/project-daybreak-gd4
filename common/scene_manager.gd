extends Node2D
class_name SceneManager 

# Structure is "FilePath" : [ packed scene, Time to live ]
var scenes_ready : Dictionary
var scenes_waiting : Array


@onready var activity_interface_wrapper = $InterfaceActivityWrapper
@onready var activity_interface = $InterfaceActivityWrapper/InterfaceActivity
@onready var world_interface = $InterfaceWorld

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

# Right now, just a collection of commented-out call templates
# Soon, a loader of multiple levels at once.
func idkwhatthisisyet_man_ijustwanna_like_uhhh_loadsevenlevelsatthesametime():
	#SceneTree.change_scene_to_packed ( PackedScene packed_scene ) # Replace a scene with a packed scene
	#ResourceLoader.load_threaded_request(SCENE_PATH)
	
	#var next_scene = ...
	#if next_scene.get_parent():
	#	next_scene.get_parent().remove_child(next_scene)
	#GlobalRuntime.scene_root_node.add_child(next_scene)
	
	pass

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


func change_map( map:String ):
	
	var old_children = world_interface.get_children()
	
	var next_map;
	
	if scenes_ready.has(map):
		next_map = scenes_ready[map][0]
		scenes_ready.erase( map )
	else:
		next_map = load( map ).new()
	
	#if scenes_ready.has(map):
	for child in world_interface.get_children():
		if child is LevelMap:
			child.pack_up()
		GlobalRuntime.clean_up_node_descent( child )
	
	
	
	world_interface.add_child( next_map ) #.instantiate()
	
	pass



func append_preload_map( map:String ):
	if !scenes_ready.has(map):
		if map.length() > 0:
			ResourceLoader.load_threaded_request(map)
			scenes_waiting.append(map)
	else:
		scenes_ready[map][1] = TTL_RESET;



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
			GlobalRuntime.clean_up_node_descent( scenes_ready[rs][0] )
			scenes_ready.erase(rs)
	
	pass
