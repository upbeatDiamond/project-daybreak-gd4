extends Node
# This class is dedicated to the fetching and manipulation of game features

var gameworld_input_stopped: bool	# Can the player move the characters/world?
var gameworld_is_paused: bool		# Can the characters/world move around on their own?

var scene_root_node

@export var scene_root_path := ^"/root/SceneManager/CurrentScene" :
	get:
		return scene_root_path
	set(value):
		scene_root_path = value
		scene_root_node = get_node(value)

# Cleans up all children of a node, and their children, and their children, etc
func clean_up_descent( target_node : Node ):
	var mark_for_deletion : Array = target_node.get_children()
	var current_mark
	
	if target_node.get_parent() != null:
		target_node.reparent(null)
	
	while mark_for_deletion.size() > 0:
		current_mark = mark_for_deletion.pop_front()
		mark_for_deletion.append_array( current_mark.get_children() )
		current_mark.queue_free()

# Queues deletion of a node and all of its child nodes
# This is intended to slow down inevitable memory leakage
# Maybe the arrays mess this up, but it also helps clean up scene transitions sometimes
func clean_up_node_descent( target_node : Node ):
	clean_up_descent(target_node)
	target_node.queue_free()
