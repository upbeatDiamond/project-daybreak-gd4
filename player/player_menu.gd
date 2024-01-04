extends CanvasLayer
class_name PlayerMenu

@onready var select_arrow = $Control/NinePatchRect/SelectionArrow
@onready var menu = $Control

var screen_loaded = ScreenLoaded.CLOSED

enum ScreenLoaded 
{ 
	CLOSED, 
	PAUSE_MENU, 
	PARTY_SCREEN,
	JOURNAL,
	INVENTORY,
	APP_HOME,
	PROFILE,
	CAMP,
	COMMUNICATIONS,
	SETTINGS,
	SAVE,
	QUIT_GAME,
}

var screen_name : Dictionary = {
	ScreenLoaded.CLOSED 		: DEFAULT_SUBMENU_NAME,
	ScreenLoaded.PAUSE_MENU 	: DEFAULT_SUBMENU_NAME,
	ScreenLoaded.PARTY_SCREEN 	: DEFAULT_SUBMENU_NAME,
	ScreenLoaded.JOURNAL 		: DEFAULT_SUBMENU_NAME,
	ScreenLoaded.INVENTORY 		: DEFAULT_SUBMENU_NAME,
	ScreenLoaded.APP_HOME 		: DEFAULT_SUBMENU_NAME,
	ScreenLoaded.PROFILE 		: DEFAULT_SUBMENU_NAME,
	ScreenLoaded.CAMP 			: DEFAULT_SUBMENU_NAME,
	ScreenLoaded.COMMUNICATIONS : DEFAULT_SUBMENU_NAME,
	ScreenLoaded.SETTINGS 		: DEFAULT_SUBMENU_NAME,
	ScreenLoaded.SAVE 			: DEFAULT_SUBMENU_NAME,
	ScreenLoaded.QUIT_GAME 		: DEFAULT_SUBMENU_NAME
}

var selected_option: int = 0
var option_count: int = 11
const DEFAULT_SUBMENU_NAME := "PausedList"
var submenu_name := DEFAULT_SUBMENU_NAME
const INPUT_COOLDOWN_DEFAULT := 0.1
var input_cooldown := INPUT_COOLDOWN_DEFAULT


func get_screen_name( tag:ScreenLoaded ):
	return screen_name[ tag ]

func _ready():
	menu.visible = false
	
	update_submenu()
	
	update_select_arrow()

#func _process(_delta):
#	if Input.is_action_pressed("menu"):
#		handle_input( InputMap.action_get_events("menu")[0] )

func update_select_arrow():
	#	select_arrow.rect_position.y = [default y] + (selected_option % 6) * [distance between options = richtext height + vbox separation]
	select_arrow.position.y = 56 + posmod(selected_option, option_count) * 49

func update_submenu():
	submenu_name = get_screen_name( screen_loaded )
	option_count = get_parent().find_child(submenu_name).get_child_count()
	selected_option = 0
	
	pass

func _process(delta):
	if input_cooldown <= 0:
		input_cooldown = INPUT_COOLDOWN_DEFAULT
		handle_input(Input)
	else:
		input_cooldown -= delta

#func _unhandled_input(event):
#	handle_input(event)

func handle_input(event):
	#event = 
	#print(event)
	match screen_loaded:
		ScreenLoaded.CLOSED:
			if event.is_action_pressed("menu", true):
				#var player = GlobalRuntime.overworld_root_node.get_children().back().find_child("Player")
				#if player == null: return
				#if GlobalRuntime.player_menu_enabled: return
				
				GlobalRuntime.gamepieces_set_paused(true);
				
				#if !player.is_moving:
					#player.set_physics_process(false)
				menu.visible = true
				screen_loaded = ScreenLoaded.PAUSE_MENU
			else:
				input_cooldown = 0
		ScreenLoaded.PARTY_SCREEN:
			print("Feature Unfinished: Load Party Screen")
			input_cooldown = 0
			pass
		
		ScreenLoaded.SAVE:
			print("Feature Unfinished: Save")
			await GlobalRuntime.save_game_data()
			# should wait between saving gamepieces and committing...
			GlobalDatabase.commit_save_from_active()
			screen_loaded = ScreenLoaded.PAUSE_MENU
			input_cooldown = 0
			selected_option = (ScreenLoaded.SAVE) % option_count
			print(selected_option, " ", option_count)
			update_select_arrow()
			pass
		
		_: #ScreenLoaded.PAUSE_MENU:
			
			if event.is_action_pressed("ui_accept"):
				var next_submenu = get_parent().find_child(submenu_name).get_child(selected_option)
				screen_loaded = next_submenu.submenu_link
				update_submenu()
			
			if event.is_action_pressed("menu", true) or \
			event.is_action_pressed("ui_cancel") or screen_loaded == ScreenLoaded.CLOSED:
				#var player = GlobalRuntime.overworld_root_node.get_children().back().find_child("Player")
				#if player == null: return
				GlobalRuntime.gamepieces_set_paused(false)
				#player.set_physics_process(true)
				menu.visible = false
				screen_loaded = ScreenLoaded.CLOSED
				
			elif event.is_action_pressed("ui_down"):
				selected_option = (selected_option + 1) % option_count
				update_select_arrow()
				
			elif event.is_action_pressed("ui_up"):
				selected_option = (selected_option - 1) % option_count
				update_select_arrow()
				
			else:
				input_cooldown = 0
