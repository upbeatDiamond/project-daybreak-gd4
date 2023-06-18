extends CanvasLayer
class_name PlayerMenu

@onready var select_arrow = $Control/NinePatchRect/SelectionArrow
@onready var menu = $Control

var screen_loaded = ScreenLoaded.CLOSED

var selected_option: int = 0
var option_count: int = 11
const DEFAULT_SUBMENU_NAME := "OptionList"
var submenu_name := DEFAULT_SUBMENU_NAME

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
	ScreenLoaded.SAVE 			: DEFAULT_SUBMENU_NAME
}

func get_screen_name( tag:ScreenLoaded ):
	return screen_name[ tag ]

func _ready():
	menu.visible = false
	
	update_submenu()
	
	update_select_arrow()


func update_select_arrow():
	#	select_arrow.rect_position.y = [default y] + (selected_option % 6) * [distance between options]
	select_arrow.position.y = 56 + posmod(selected_option, option_count) * 49

func update_submenu():
	submenu_name = get_screen_name( screen_loaded )
	option_count = get_parent().find_child(submenu_name).get_child_count()
	
	pass

func _unhandled_input(event):
	match screen_loaded:
		ScreenLoaded.CLOSED:
			if event.is_action_pressed("menu"):
				var player = GlobalRuntime.scene_root_node.get_children().back().find_child("Player")
				if player == null: return
				if GlobalRuntime.player_menu_enabled: return
				if !player.is_moving:
					player.set_physics_process(false)
					menu.visible = true
					screen_loaded = ScreenLoaded.PAUSE_MENU
			
		ScreenLoaded.PARTY_SCREEN:
			print("Feature Unfinished: Load Party Screen")
			pass
		
		
		_: #ScreenLoaded.PAUSE_MENU:
			
			if event.is_action_pressed("ui_accept"):
				var next_submenu = get_parent().find_child(submenu_name).get_child(selected_option)
				screen_loaded = next_submenu.submenu_link
				update_submenu()
			
			if event.is_action_pressed("menu") or event.is_action_pressed("ui_cancel") or screen_loaded == ScreenLoaded.CLOSED:
				var player = GlobalRuntime.scene_root_node.get_children().back().find_child("Player")
				if player == null: return
				player.set_physics_process(true)
				menu.visible = false
				screen_loaded = ScreenLoaded.CLOSED
				
			elif event.is_action_pressed("ui_down"):
				selected_option = (selected_option + 1) % option_count
				update_select_arrow()
				
			elif event.is_action_pressed("ui_up"):
				selected_option = (selected_option - 1) % option_count
				update_select_arrow()
			
