extends Node
# Merge with GlobalGameworldTime/GlobalDayCycle?

var gameworld_input_stopped: bool	# Can the player move the characters/world?
var gameworld_is_paused: bool		# Can the characters/world move around on their own?

var scene_root_node

@export var scene_root_path := ^"/root/SceneManager/CurrentScene" :
	get:
		return scene_root_path
	set(value):
		scene_root_path = value
		scene_root_node = get_node(value)
