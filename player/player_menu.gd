extends CanvasLayer
class_name PlayerMenu

@onready var select_arrow = $Control/PauseRect/SelectionArrow
@onready var menu = $Control
@onready var inventory_gui = $Control/InventoryGUI
@onready var pause_list = $Control/PauseRect/PausedList

var screen_selected = ScreenListing.CLOSED

#static signal submenu_escaped( source:ScreenListing, target )

enum ScreenListing 
{ 
	CLOSED, 
	PAUSE_MENU, 
	PARTY_SCREEN,
	JOURNAL,
	INVENTORY,
	APP_HOME,
	PROFILE,
	CAMP,
	COMMS,
	SETTINGS,
	SAVE,
	QUIT_GAME,
}

var screen_name : Dictionary = {
	ScreenListing.CLOSED 		: SUBMENU_NAME_DEFAULT,
	ScreenListing.PAUSE_MENU 	: SUBMENU_NAME_DEFAULT,
	ScreenListing.PARTY_SCREEN 	: SUBMENU_NAME_DEFAULT,
	ScreenListing.JOURNAL 		: SUBMENU_NAME_DEFAULT,
	ScreenListing.INVENTORY 	: SUBMENU_NAME_INVENTORY,
	ScreenListing.APP_HOME 		: SUBMENU_NAME_DEFAULT,
	ScreenListing.PROFILE 		: SUBMENU_NAME_DEFAULT,
	ScreenListing.CAMP 			: SUBMENU_NAME_DEFAULT,
	ScreenListing.COMMS			: SUBMENU_NAME_DEFAULT,
	ScreenListing.SETTINGS 		: SUBMENU_NAME_DEFAULT,
	ScreenListing.SAVE 			: SUBMENU_NAME_DEFAULT,
	ScreenListing.QUIT_GAME 	: SUBMENU_NAME_DEFAULT
}

var supermenu : Dictionary = {
	ScreenListing.CLOSED 		: ScreenListing.CLOSED,
	ScreenListing.PAUSE_MENU	: ScreenListing.CLOSED, 
	ScreenListing.INVENTORY		: ScreenListing.PAUSE_MENU,
}

var selected_option: int = 0
var option_count: int = 11
const SUBMENU_NAME_DEFAULT := "PausedList"
const SUBMENU_NAME_INVENTORY := "InventoryList"
var submenu_name := SUBMENU_NAME_DEFAULT
const INPUT_COOLDOWN_DEFAULT := 0.1
var input_cooldown := INPUT_COOLDOWN_DEFAULT


func get_screen_name( tag:ScreenListing ):
	return screen_name[ tag ]


func _ready():
	menu.visible = false
	update_submenu()
	update_select_arrow()
	#submenu_escaped.connect( _on_submenu_escaped )


#static func submenu_escaped_emit( submenu_context, submenu_excape ):
#	submenu_escaped.emit( submenu_context, submenu_excape )

func _on_submenu_escaped( source:ScreenListing, target=null ):
	if target is ScreenListing:
		screen_selected = target as ScreenListing
	elif supermenu.has(source):
		screen_selected = supermenu[source]
	else:
		screen_selected = ScreenListing.PAUSE_MENU
	update_submenu()
	update_select_arrow()


func update_select_arrow():
	# 56 = assumed default/initial y-offset
	# 49 = height of line + margin
	select_arrow.position.y = 56 + posmod(selected_option, option_count) * 49


func update_submenu():
	submenu_name = get_screen_name( screen_selected )
	var options = get_parent().find_child(submenu_name, true)
	option_count = 0
	if options != null:
		option_count = options.get_child_count()
	selected_option = 0
	
	pass


func _process(delta):
	if input_cooldown <= 0:
		input_cooldown = INPUT_COOLDOWN_DEFAULT
		handle_input(Input)
	else:
		input_cooldown -= delta


func handle_input(event):
	match submenu_name:
		SUBMENU_NAME_INVENTORY:
			inventory_gui.visible = true
			if event.is_action_pressed("ui_cancel", true):
				screen_selected = ScreenListing.PAUSE_MENU
				update_submenu()
				inventory_gui.visible = false
				menu.visible = true
				pause_list.visible = true
				GlobalRuntime.gamepieces_set_paused(true);
				update_select_arrow()
			pass
		_: #SUBMENU_NAME_DEFAULT
			match screen_selected:
				ScreenListing.CLOSED:
					if event.is_action_pressed("menu", true):
						GlobalRuntime.gamepieces_set_paused(true);
						
						menu.visible = true
						screen_selected = ScreenListing.PAUSE_MENU
						update_submenu()
					else:
						input_cooldown = 0
				
				ScreenListing.PARTY_SCREEN:
					print("Feature Unfinished: Load Party Screen")
					input_cooldown = 0
					pass
				
				ScreenListing.SAVE:
					print("Feature Unfinished: Save")
					await GlobalRuntime.save_game_data()
					# should wait between saving gamepieces and committing...
					GlobalDatabase.commit_save_from_active()
					screen_selected = ScreenListing.PAUSE_MENU
					input_cooldown = 0
					selected_option = (ScreenListing.SAVE) % option_count
					print(selected_option, " ", option_count)
					update_select_arrow()
					pass
				
				
				ScreenListing.INVENTORY:
					
					inventory_gui.visible = true
					menu.visible = true
					pause_list.visible = false
					screen_selected = ScreenListing.PAUSE_MENU
					submenu_name = SUBMENU_NAME_INVENTORY
				
				_: #ScreenListing.PAUSE_MENU:
					
					if event.is_action_pressed("ui_accept"):
						var next_submenu = get_parent().find_child(submenu_name).get_child(selected_option)
						screen_selected = next_submenu.submenu_link
						update_submenu()
					
					if event.is_action_pressed("menu", true) or \
					event.is_action_pressed("ui_cancel") or screen_selected == ScreenListing.CLOSED:
						GlobalRuntime.gamepieces_set_paused(false)
						menu.visible = false
						screen_selected = ScreenListing.CLOSED
						
					elif event.is_action_pressed("ui_down"):
						selected_option = (selected_option + 1) % option_count
						update_select_arrow()
						
					elif event.is_action_pressed("ui_up"):
						selected_option = (selected_option - 1) % option_count
						update_select_arrow()
						
					else:
						input_cooldown = 0
						pause_list.visible = true
