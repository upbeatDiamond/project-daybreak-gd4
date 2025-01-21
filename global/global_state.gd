extends Node
## This class is dedicated to the maintenence of world states, world queries, and interface changes

var server_random : RandomNumberGenerator
var multiplayer_enabled: bool
var rw_mode := RWMode.DEVELOPMENT ## RW Mode = Read/Write/Run Mode

const META_INPUT_COOLDOWN_RESET := 0.05
var meta_input_cooldown := 0.0

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

## RW Mode = Read/Write/Run Mode
enum RWMode { 
	DEBUG, 			## Debug should make symbols apparent and print excessively
	DEVELOPMENT,	## Development should be allowed to save to template database(s)
	DEMO,			## Demo should hide unfinished/unstable features
	RELEASE			## Release should hide silly 'print' statements
}

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
	WORLD_MENU_CLOSE,
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
	WORLD_DIALOG_ENDED, ## Unused?
	
	ANYTHING,	## Similar to a MAX, this is for transition statements
}

const STATES_WORLD_VISIBLE := [
	GameIOState.WORLD, 
	GameIOState.WORLD_TRANSITION, ## For pausing menu access; should activate interact on finish
	GameIOState.WORLD_DIALOG,
	GameIOState.WORLD_MENU,
	GameIOState.WORLD_MENU_SAVE,
	GameIOState.WORLD_MENU_CLOSE,
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
const STATES_TIME_PROGRESS := [
	GameIOState.WORLD, 
	GameIOState.WORLD_TRANSITION, ## For pausing menu access; should activate interact on finish
	GameIOState.WORLD_DIALOG,
	GameIOState.WORLD_MENU,
	GameIOState.WORLD_MENU_SAVE,
	GameIOState.WORLD_MENU_CLOSE,
	GameIOState.WORLD_MENU_QUIT,
	GameIOState.WORLD_DIALOG_QUEUE_BATTLE, 
	GameIOState.WORLD_DIALOG_ENDED,
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
	GameIOState.WORLD_MENU : {
		GameIOState.WORLD_MENU_CLOSE: GameIOState.WORLD
	}
}


var current_io_state := GameIOState.TITLE_MENU


func _init():
	server_random = RandomNumberGenerator.new()
	server_random.randomize()


func _ready():
	_switch_io_state(current_io_state)


func _process(_delta: float) -> void:
	
	if Input.is_action_pressed("menu") and meta_input_cooldown > 0:
		meta_input_cooldown = max( meta_input_cooldown, META_INPUT_COOLDOWN_RESET )
	
	if meta_input_cooldown > 0:
		meta_input_cooldown = meta_input_cooldown - _delta
		if meta_input_cooldown > 0:
			return
	
	if Input.is_action_pressed("menu"):
		meta_input_cooldown = max( meta_input_cooldown, META_INPUT_COOLDOWN_RESET )
		print(STATES_TOGGLE_PLAYER_MENU)
		if STATES_TOGGLE_PLAYER_MENU.find( current_io_state ) >= 0 :
			_switch_io_state( STATES_TOGGLE_PLAYER_MENU[ STATES_TOGGLE_PLAYER_MENU.find(current_io_state) - 1] )
	pass



func _input(event):
	#if event.is_action_pressed("game_pause"):
		#gamepieces_set_paused( !gamepieces_paused ) 
		## use GameIOState.PAUSED_DEBUG if this is restored
	if event.is_action_pressed("debug_print"):
		print( current_io_state, "/", GameIOState.find_key(current_io_state), " is the IO state?" )
	pass


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


func screen_transition( style := "fade" ):
	scene_transition_player.play(style)
	await scene_transition_player.animation_finished


# It feels like a Runtime access thing...
# But it relies on the Scene Manager's structure and knowledge...
# So why not host the function call and pass it over?
func switch_to_interface( interface:SceneManager.InterfaceOptions ):
	scene_manager.switch_to_interface( interface )


func is_player_menu_enabled() -> bool:
	return current_io_state in STATES_TOGGLE_PLAYER_MENU


func is_gamepiece_input_ignored() -> bool:
	return not (current_io_state in STATES_PLAYER_CAN_MOVE)


func is_all_gamepieces_paused() -> bool:
	return not (current_io_state in STATES_ANYONE_CAN_MOVE)


func should_time_progress() -> bool:
	return current_io_state in STATES_TIME_PROGRESS


## Copied & modified from "JRPG Demo"
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
	
	return prior_state
