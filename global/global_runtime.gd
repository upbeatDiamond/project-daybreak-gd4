extends Node
# This class is dedicated to the fetching and manipulation of game features

const DEFAULT_TILE_SIZE := 16

var gameworld_input_stopped: bool	# Can the player move the characters/world?
var gameworld_is_paused: bool		# Can the characters/world move around on their own?

var scene_root_node : Node

@export var combat_screen : Node
@export var scene_transition_player : Node

@export var scene_root_path := ^"/root/SceneManager/CurrentScene" :
	get:
		return scene_root_path
	set(value):
		scene_root_path = value
		scene_root_node = get_node(value)

func _ready():
	scene_root_path = scene_root_path

# Cleans up all children of a node, and their children, and their children, etc
func clean_up_descent( target_node : Node ):
	var mark_for_deletion : Array = target_node.get_children()
	var current_mark
	
	if target_node.get_parent() != null:
		target_node.reparent(null)
	
	while mark_for_deletion.size() > 0:
		current_mark = mark_for_deletion.pop_front()
		mark_for_deletion.append_array( current_mark.get_children() )
		if current_mark.has_method("clean_up"): current_mark.clean_up()
		current_mark.queue_free()

# Queues deletion of a node and all of its child nodes
# This is intended to slow down inevitable memory leakage
# Maybe the arrays mess this up, but it also helps clean up scene transitions sometimes
func clean_up_node_descent( target_node : Node ):
	clean_up_descent(target_node)
	target_node.queue_free()


func freeze_scene(node, freeze):
	var mark_for_freeze : Array = node.get_children()
	var current_mark
	
	while mark_for_freeze.size() > 0:
		current_mark = mark_for_freeze.pop_front()
		mark_for_freeze.append_array( current_mark.get_children() )
		freeze_node(current_mark, freeze)
	pass

func freeze_node(node, freeze):
	node.set_process(!freeze)
	node.set_physics_process(!freeze)
	node.set_process_input(!freeze)
	node.set_process_internal(!freeze)
	node.set_process_unhandled_input(!freeze)
	node.set_process_unhandled_key_input(!freeze)

	pass

func screen_transition( style := "fade" ):
	scene_transition_player.play(style)
	await scene_transition_player.animation_finished


# Copied & modified from "JRPG Demo", do not use yet.
func start_combat(combat_actors):
	screen_transition()
	scene_root_node.add_child(combat_screen)
	combat_screen.show()
	combat_screen.initialize(combat_actors)
	$AnimationPlayer.play_backwards("fade")
