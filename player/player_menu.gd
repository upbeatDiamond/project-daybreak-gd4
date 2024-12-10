extends CanvasLayer
class_name PlayerMenu

@onready var select_arrow_icon = preload("res://assets/textures/menu/selection_arrow.png")
@onready var select_arrow_blank = preload("res://assets/textures/menu/selection_arrow_transparent.png")
@onready var item_list = $Control/PauseRect/ItemList
#@onready var inventory_gui = $Control/InventoryGUI
#@onready var pause_list = $Control/PauseRect/PausedList

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

var selected_option: int = 0
var option_count: int = 11
const SUBMENU_NAME_DEFAULT := "PausedList"
const SUBMENU_NAME_INVENTORY := "InventoryList"
var submenu_name := SUBMENU_NAME_DEFAULT
const INPUT_COOLDOWN_DEFAULT := 0.1
var input_cooldown := INPUT_COOLDOWN_DEFAULT


func _ready():
	self.visible = false
	item_list.item_selected.connect(update_cursor)
	update_cursor()
	#submenu_escaped.connect( _on_submenu_escaped )


func update_cursor(new_index:int=selected_option):
	# 56 = assumed default/initial y-offset
	# 49 = height of line + margin
	item_list.set_item_icon(posmod(selected_option, item_list.item_count), select_arrow_blank)
	selected_option = posmod(new_index, item_list.item_count)
	item_list.set_item_icon(selected_option, select_arrow_icon)
	item_list.select( new_index )


func _process(delta):
	if GlobalRuntime.current_io_state == GlobalRuntime.GameIOState.WORLD_MENU:
		visible = true
		item_list.grab_focus()
		item_list.grab_click_focus()
		if input_cooldown <= 0:
			handle_input(Input)
			#input_cooldown = INPUT_COOLDOWN_DEFAULT
		else:
			input_cooldown -= delta
	else:
		visible = false


func handle_input(event):
	
	if event.is_action_pressed("ui_accept"):
		screen_selected = item_list.item_submenu_links[ item_list.get_selected_items()[0] ]
		trigger_submenu()
		input_cooldown = INPUT_COOLDOWN_DEFAULT
	
	elif event.is_action_pressed("ui_down"):
		item_list.select( posmod( (item_list.get_selected_items()[0] + 1), item_list.item_count) )
		update_cursor()
		input_cooldown = INPUT_COOLDOWN_DEFAULT
	
	elif event.is_action_pressed("ui_up"):
		item_list.select( posmod( (item_list.get_selected_items()[0] - 1), item_list.item_count) )
		update_cursor()
		input_cooldown = INPUT_COOLDOWN_DEFAULT
	
	else:
		input_cooldown = 0
		visible = true


func trigger_submenu():
	match screen_selected:
		ScreenListing.CLOSED:
			GlobalRuntime._switch_io_state(GlobalRuntime.GameIOState.WORLD_MENU_CLOSE)
		
		ScreenListing.PARTY_SCREEN:
			pass #GlobalRuntime.scene_manager.mount_activity( ?, GlobalRuntime.GameIOState.WORLD_MENU_PARTY)
		
		ScreenListing.SAVE:
			print("Feature Unfinished: Save")
			await GlobalRuntime.save_game_data()
			# should wait between saving gamepieces and committing...
			GlobalDatabase.commit_save_from_active()
			#selected_option = (ScreenListing.SAVE) % option_count
			#print(selected_option, " ", option_count)
			update_cursor(0)
			pass
		
		ScreenListing.PAUSE_MENU:
			pass #GlobalRuntime.scene_manager.mount_activity( ?, GlobalRuntime.GameIOState.WORLD_MENU_PARTY)

		ScreenListing.JOURNAL:
			pass #GlobalRuntime.scene_manager.mount_activity( ?, GlobalRuntime.GameIOState.WORLD_MENU_PARTY)
		ScreenListing.APP_HOME:
			pass #GlobalRuntime.scene_manager.mount_activity( ?, GlobalRuntime.GameIOState.WORLD_MENU_PARTY)
		ScreenListing.PROFILE:
			pass #GlobalRuntime.scene_manager.mount_activity( ?, GlobalRuntime.GameIOState.WORLD_MENU_PARTY)
		ScreenListing.CAMP:
			pass #GlobalRuntime.scene_manager.mount_activity( ?, GlobalRuntime.GameIOState.WORLD_MENU_PARTY)
		ScreenListing.COMMS:
			pass #GlobalRuntime.scene_manager.mount_activity( ?, GlobalRuntime.GameIOState.WORLD_MENU_PARTY)
		ScreenListing.SETTINGS:
			pass #GlobalRuntime.scene_manager.mount_activity( ?, GlobalRuntime.GameIOState.WORLD_MENU_PARTY)

		ScreenListing.QUIT_GAME:
			pass
		
		ScreenListing.INVENTORY:
			pass #GlobalRuntime.scene_manager.mount_activity( ?, GlobalRuntime.GameIOState.WORLD_MENU_INVENTORY)
		
		_: #ScreenListing.PAUSE_MENU:
			GlobalRuntime._switch_io_state(GlobalRuntime.GameIOState.WORLD_MENU)
			
