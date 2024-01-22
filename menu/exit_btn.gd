extends TextureButton

@export var submenu_context := PlayerMenu.ScreenListing.INVENTORY
@export var submenu_excape := PlayerMenu.ScreenListing.PAUSE_MENU

func _ready():
	action_mode = ACTION_MODE_BUTTON_PRESS
	#pressed.connect(_on_pressed_self)

#func _on_pressed_self():
	#PlayerMenu.submenu_escaped_emit( submenu_context, submenu_excape )
	## ...which does nothing at the moment, but should soon return to a supermenu of the current 
	#pass
