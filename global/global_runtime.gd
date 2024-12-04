extends Node
# This class is dedicated to the fetching and manipulation of game features

const DEFAULT_TILE_SIZE := 16
const DEFAULT_TILE_OFFSET := Vector2.ONE * floor(  (GlobalRuntime.DEFAULT_TILE_SIZE + 1)/2.0 )
const DEFAULT_TILE_OFFSET_INT := Vector2i( DEFAULT_TILE_OFFSET )
const CAMERA_TWEEN_DURATION := 1.0

var gamepiece_input_ignored: bool	# Can the player move the characters/world?
var gamepieces_paused: bool		# Can the characters/world move around on their own?
var player_menu_enabled: bool		# Can the player open their menu?
var multiplayer_enabled: bool

@export var combat_screen : Node
@export var scene_transition_player : Node

@onready var scene_manager : SceneManager = get_node(^"/root/SceneManager")

@export var overworld_root_path := ^"/root/SceneManager/PlayerCamView/SubViewport/InterfaceWorld" :
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


signal pause_gameworld
signal unpause_gameworld
signal save_data



enum GameIOState {
	TITLE_MENU,
	TITLE_MENU_OPTIONS,
	TITLE_MENU_CONNECTION,
	TITLE_MENU_CREDITS,
	TITLE_MENU_QUIT,
	WORLD,
	WORLD_TRANSITION, ## Restrict menu access & activate 'interact' on finish
	WORLD_DIALOG,
	WORLD_MENU,
	WORLD_MENU_JOURNAL,
	WORLD_MENU_PARTY,
	WORLD_MENU_INVENTORY,
	WORLD_MENU_APP,
	WORLD_MENU_PROFILE,
	WORLD_MENU_CAMP,
	WORLD_MENU_SETTINGS,
	WORLD_MENU_SAVE,
	WORLD_MENU_EXIT,
	WORLD_MENU_QUIT,
	BATTLE,
	ACTIVITY,
	CINEMATIC_STARTED,
	CINEMATIC_QUEUE_WORLD,
	CINEMATIC_ENDED,
	WORLD_PAUSED,
	PAUSED_DEBUG, ## Avoid using! For debug purposes!
	CINEMATIC_QUEUE_BATTLE,
	WORLD_DIALOG_QUEUE_BATTLE,
}

const STATES_WORLD_VISIBLE := [
	GameIOState.WORLD, 
	GameIOState.WORLD_TRANSITION, ## For pausing menu access; should activate interact on finish
	GameIOState.WORLD_DIALOG,
	GameIOState.WORLD_MENU,
	GameIOState.WORLD_MENU_SAVE,
	GameIOState.WORLD_MENU_EXIT,
	GameIOState.WORLD_MENU_QUIT,
	GameIOState.WORLD_PAUSED,
]
const STATES_TITLESCREEN := [
	GameIOState.TITLE_MENU,
	GameIOState.TITLE_MENU_OPTIONS,
	GameIOState.TITLE_MENU_CONNECTION,
	GameIOState.TITLE_MENU_CREDITS,
	GameIOState.TITLE_MENU_QUIT,
]
const STATES_BATTLE := [
	GameIOState.BATTLE,
]
const STATES_WORLD_QUEUED := [
	GameIOState.CINEMATIC_QUEUE_WORLD,
	GameIOState.CINEMATIC_ENDED,
	GameIOState.WORLD_PAUSED,
]
const STATES_ACTIVITY := [
	GameIOState.ACTIVITY
]
const STATES_TOGGLE_PLAYER_MENU := [
	GameIOState.WORLD, 
	GameIOState.WORLD_MENU
]
const STATES_PLAYER_CAN_MOVE := [
	GameIOState.WORLD
]
const STATES_ANYONE_CAN_MOVE := [
	GameIOState.WORLD,
	GameIOState.WORLD_TRANSITION,
	GameIOState.WORLD_DIALOG,
]
const STATES_DIALOG_ENABLED := [
	GameIOState.WORLD,
]
const STATES_PLAYER_INTERACT_ON_EXIT := [
	GameIOState.WORLD_TRANSITION,
]
const STATES_DIALOG_ACTIVE := [
	GameIOState.WORLD_DIALOG,
]

## Prior : { Next : Redirect }
const STATE_TRANSITION_EXCEPTIONS := {
	GameIOState.CINEMATIC_STARTED : { 
		GameIOState.WORLD : GameIOState.CINEMATIC_QUEUE_WORLD,
		GameIOState.CINEMATIC_ENDED : GameIOState.WORLD, # World is default exit?
		GameIOState.BATTLE : GameIOState.CINEMATIC_QUEUE_BATTLE,
		},
	GameIOState.CINEMATIC_QUEUE_WORLD : {
		GameIOState.WORLD : GameIOState.CINEMATIC_QUEUE_WORLD,
		GameIOState.CINEMATIC_STARTED : GameIOState.CINEMATIC_QUEUE_WORLD,
		GameIOState.CINEMATIC_ENDED : GameIOState.WORLD,
		GameIOState.BATTLE : GameIOState.CINEMATIC_QUEUE_BATTLE,
		},
	GameIOState.WORLD : {
		GameIOState.CINEMATIC_STARTED : GameIOState.CINEMATIC_QUEUE_WORLD,
		GameIOState.PAUSED_DEBUG : GameIOState.WORLD_PAUSED
		},
	GameIOState.CINEMATIC_QUEUE_BATTLE : {
		GameIOState.WORLD : GameIOState.CINEMATIC_QUEUE_BATTLE,
		GameIOState.CINEMATIC_STARTED : GameIOState.CINEMATIC_QUEUE_BATTLE,
		GameIOState.CINEMATIC_ENDED : GameIOState.BATTLE,
		GameIOState.BATTLE : GameIOState.CINEMATIC_QUEUE_BATTLE,
		},
	GameIOState.WORLD_DIALOG : {
		GameIOState.BATTLE : GameIOState.WORLD_DIALOG_QUEUE_BATTLE,
		},
	GameIOState.WORLD_DIALOG_QUEUE_BATTLE : {
		GameIOState.BATTLE : GameIOState.WORLD_DIALOG_QUEUE_BATTLE,
		GameIOState.WORLD : GameIOState.BATTLE,
		GameIOState.WORLD_DIALOG : GameIOState.WORLD_DIALOG_QUEUE_BATTLE,
		},
}


var current_io_state := GameIOState.TITLE_MENU


func _ready():
	#scene_root_node = get_node(scene_root_path)
	_switch_io_state(current_io_state)
	pass


# Cleans up all children of a node, and their children, and their children, etc
func clean_up_descent( target_node : Node ):
	var mark_for_deletion : Array = target_node.get_children()
	var current_mark
	
	while mark_for_deletion.size() > 0:
		current_mark = mark_for_deletion.pop_front()
		mark_for_deletion.append_array( current_mark.get_children() )
		
		if target_node.get_parent() != null: 
			target_node.get_parent().remove_child( target_node )
			
		if current_mark.has_method("clean_up"): 
			current_mark.clean_up()
			
		current_mark.queue_free()


func _input(event):
	#if event.is_action_pressed("game_pause"):
		#gamepieces_set_paused( !gamepieces_paused ) 
		## use GameIOState.PAUSED_DEBUG if this is restored
	if event.is_action_pressed("debug_print"):
		print( GameIOState.find_key(current_io_state), " is the IO state?" )
	pass



##  Returns prior state of boolean
func gameworld_input_enabled( value:bool ) -> bool:
	print("DEPRICATED FUNCTIONALITY! GAMEPIECE IGNORE INPUT => STATE TRANSITION")
	var _ret = not gamepiece_input_ignored
	gamepiece_input_ignored = not value
	return _ret


func gamepieces_set_paused( value:bool ):
	print("DEPRICATED FUNCTIONALITY! GAMEPIECE SET PAUSED => STATE TRANSITION")
	if value and multiplayer_enabled:
		## TODO: If online multiplayer, don't pause the whole world, just this session's player.
		pause_gameworld.emit()
		#gamepieces_paused
	elif value:
		pause_gameworld.emit()
		gamepieces_paused = true
	else:
		unpause_gameworld.emit()
		gamepieces_paused = false


# Queues deletion of a node and all of its child nodes
# This is intended to slow down inevitable memory leakage
# Maybe the arrays mess this up, but it also helps clean up scene transitions sometimes
# Might be redudant? Depends on how Godot implements queue_free
func clean_up_node_descent( target_node : Node ):
	if target_node.has_method("clean_up"):
		target_node.clean_up()
	clean_up_descent(target_node)
	#if target_node.get_parent() != null:
	#	target_node.get_parent().remove_child(target_node)
	target_node.queue_free()


func freeze_scene(node:Node, freeze:bool):
	var mark_for_freeze : Array = node.get_children()
	var current_mark
	
	while mark_for_freeze.size() > 0:
		current_mark = mark_for_freeze.pop_front()
		mark_for_freeze.append_array( current_mark.get_children() )
		freeze_node(current_mark, freeze)
	pass


func freeze_node(node:Node, freeze:bool):
	node.set_process(!freeze)
	node.set_physics_process(!freeze)
	node.set_process_input(!freeze)
	node.set_process_internal(!freeze)
	node.set_process_unhandled_input(!freeze)
	node.set_process_unhandled_key_input(!freeze)
	pass


func save_game_data():
	#for gp in scene_manager.get_tree().get_nodes_in_group("gamepiece"):
	#	await GlobalDatabase.save_gamepiece( gp as Gamepiece )
	save_data.emit()
	
	print("saved!");
	pass


func multiply_string( _text:String, count:int, _separator:="" ) -> String:
	var ret = ""
	if count > 0:
		ret = _text
		count -= 1
		while count > 0:
			ret = str(ret, _separator, _text)
			count -= 1
	return ret


func screen_transition( style := "fade" ):
	scene_transition_player.play(style)
	await scene_transition_player.animation_finished


func snap_to_grid( pos ) -> Vector2:
	return snap_to_grid_center_f( pos )


func snap_to_grid_center_f( pos ) -> Vector2:
	return snap_to_grid_corner_f( pos ) + DEFAULT_TILE_OFFSET


func snap_to_grid_center_i( pos ) -> Vector2i:
	return snap_to_grid_corner_i( pos ) + DEFAULT_TILE_OFFSET_INT


func snap_to_grid_corner_f( pos ) -> Vector2:
	pos = Vector2(pos.x - DEFAULT_TILE_OFFSET.x, pos.y - DEFAULT_TILE_OFFSET.y)
	return pos.snapped(Vector2.ONE * GlobalRuntime.DEFAULT_TILE_SIZE)


func snap_to_grid_corner_i( pos ) -> Vector2i:
	pos = Vector2i(pos.x - DEFAULT_TILE_OFFSET.x, pos.y - DEFAULT_TILE_OFFSET.y)
	pos = pos.snapped(Vector2i.ONE * GlobalRuntime.DEFAULT_TILE_SIZE) #+ DEFAULT_TILE_OFFSET_INT
	return pos


# It feels like a Runtime access thing...
# But it relies on the Scene Manager's structure and knowledge...
# So why not host the function call and pass it over?
func switch_to_interface( interface:SceneManager.InterfaceOptions ):
	scene_manager.switch_to_interface( interface )
	pass


func is_player_menu_enabled():
	return player_menu_enabled;


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


func _switch_io_state(new_state:GameIOState) -> GameIOState:
	var prior_state = current_io_state
	current_io_state = new_state
	
	if STATE_TRANSITION_EXCEPTIONS.has(prior_state) and \
			STATE_TRANSITION_EXCEPTIONS[prior_state].has(new_state):
		current_io_state = STATE_TRANSITION_EXCEPTIONS[prior_state][new_state]
	
	if scene_manager.is_node_ready():
		if prior_state in STATES_WORLD_QUEUED or current_io_state in STATES_WORLD_VISIBLE:
			scene_manager.switch_to_interface(scene_manager.InterfaceOptions.WORLD)
		elif current_io_state in STATES_BATTLE:
			scene_manager.switch_to_interface(scene_manager.InterfaceOptions.BATTLE)
		else:
			scene_manager.switch_to_interface(scene_manager.InterfaceOptions.ACTIVITY)
	
	gamepieces_paused = not (current_io_state in STATES_ANYONE_CAN_MOVE)
	gamepiece_input_ignored = not (current_io_state in STATES_PLAYER_CAN_MOVE)
	player_menu_enabled = current_io_state in STATES_TOGGLE_PLAYER_MENU
	
	
	
	return prior_state
