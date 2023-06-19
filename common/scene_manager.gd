extends Node2D

# Structure is "FilePath" : [ packed scene, Time to live ]
var scenes_ready : Dictionary
var scenes_waiting : Array

# Keep the -1, it's a mnemonic.
# The number preceding the '-1' is the number of levels you can access before an item expires.
const TTL_RESET := 4 - 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var i := 0
	while i < scenes_waiting.size():
		match ResourceLoader.load_threaded_get_status( scenes_waiting[i] ):
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED:
				scenes_waiting[i].erase
			ResourceLoader.THREAD_LOAD_LOADED:
				scenes_ready[ scenes_waiting[i] ] = [ResourceLoader.load_threaded_get( scenes_waiting[i] ).instance(), TTL_RESET]
				scenes_waiting[i].erase
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


func update_preload_portals( ttl_decrement : int = 1 ):
	var portals = get_tree().get_nodes_in_group("portals")
	
	# Whatever resources are not yet available, queue loading
	for portal in portals:
		if !scenes_ready.has(portal):
			ResourceLoader.load_threaded_request(portal)
			scenes_waiting.append(portal)
		else:
			scenes_ready[portal][1] = 3;
		pass
	
	# Whatever resources have not been updated, decrement their TTL
	for rs in scenes_ready.keys():
		scenes_ready[rs][1] = scenes_ready[rs][1] - abs(ttl_decrement);
		
		# If their TTL is expired, remove from the list
		if scenes_ready[rs][1] < 0:
			GlobalRuntime.clean_up_descent( scenes_ready[rs][0] )
			scenes_ready.erase(rs)
	
	pass
