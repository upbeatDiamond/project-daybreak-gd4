extends CanvasLayer

@onready var select_arrow = $Control/NinePatchRect/SelectionArrow
@onready var menu = $Control

enum ScreenLoaded { NOTHING, PAUSE_MENU, PARTY_SCREEN }
var screen_loaded = ScreenLoaded.NOTHING

var selected_option: int = 0
@export var option_count: int = 11

func _ready():
	menu.visible = false
	
	option_count = get_parent().find_child("OptionList").get_child_count()
	
	update_select_arrow()


func update_select_arrow():
	#	select_arrow.rect_position.y = [default y] + (selected_option % 6) * [distance between options]
	select_arrow.position.y = 56 + posmod(selected_option, option_count) * 49


func _unhandled_input(event):
	match screen_loaded:
		ScreenLoaded.NOTHING:
			if event.is_action_pressed("menu"):
				var player = GlobalRuntime.scene_root_node.get_children().back().find_child("Player")
				if player == null: return
				if !player.is_moving:
					player.set_physics_process(false)
					menu.visible = true
					screen_loaded = ScreenLoaded.PAUSE_MENU
			
		ScreenLoaded.PAUSE_MENU:
			if event.is_action_pressed("menu") or event.is_action_pressed("ui_cancel"):
				var player = GlobalRuntime.scene_root_node.get_children().back().find_child("Player")
				if player == null: return
				player.set_physics_process(true)
				menu.visible = false
				screen_loaded = ScreenLoaded.NOTHING
				
			elif event.is_action_pressed("ui_down"):
				selected_option = (selected_option + 1) % option_count
				update_select_arrow()
				
			elif event.is_action_pressed("ui_up"):
				selected_option = (selected_option - 1) % option_count
				update_select_arrow()
			
		ScreenLoaded.PARTY_SCREEN:
			print("Feature Unfinished: Load Party Screen")
			pass
