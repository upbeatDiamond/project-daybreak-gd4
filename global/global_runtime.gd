extends Node
# This class is dedicated to the fetching and manipulation of game features

const DEFAULT_TILE_SIZE := 16

var gameworld_input_stopped: bool	# Can the player move the characters/world?
var gameworld_is_paused: bool		# Can the characters/world move around on their own?
var player_menu_enabled: bool		# Can the player open their menu?



signal pause_gameworld
signal unpause_gameworld

@export var combat_screen : Node
@export var scene_transition_player : Node

@onready var scene_manager := get_node(^"/root/SceneManager")

@export var overworld_root_path := ^"/root/SceneManager/InterfaceWorld" :
	get:
		return overworld_root_path
	set(value):
		overworld_root_path = value
		overworld_root_node = get_node(value)

@onready var overworld_root_node : Node = get_node(overworld_root_path)

@export var activity_root_path := ^"/root/SceneManager/InterfaceActivityWrapper/InterfaceActivity" :
	get:
		return activity_root_path
	set(value):
		activity_root_path = value
		activity_root_node = get_node(value)

@onready var activity_root_node : Node = get_node(activity_root_path)


func _ready():
	#scene_root_node = get_node(scene_root_path)
	pass

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

func _input(event):
	if event.is_action_pressed("game_pause"):
		gamepieces_set_paused( !gameworld_is_paused )
	pass

func gamepieces_set_paused( value:bool ):
	if value:
		pause_gameworld.emit()
		gameworld_is_paused = true
	else:
		unpause_gameworld.emit()
		gameworld_is_paused = false

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

# It feels like a Runtime access thing...
# But it relies on the Scene Manager's structure and knowledge...
# So why not host the function call and pass it over?
func switch_to_interface( interface:SceneManager.InterfaceOptions ):
	scene_manager.switch_to_interface( interface )
	pass


# Copied & modified from "JRPG Demo", do not use yet.
func start_combat(combat_actors):
	#screen_transition()
	activity_root_node.add_child(combat_screen)
	combat_screen.show()
	scene_manager.switch_to_interface( SceneManager.InterfaceOptions.ACTIVITY )
	combat_screen.initialize(combat_actors)
	$AnimationPlayer.play_backwards("fade")

func complete_combat():
	pass
