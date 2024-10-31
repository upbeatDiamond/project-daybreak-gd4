extends Control

# not just 'enabled' in case of variable shadowing
# tracks whether buttons can do things, and might be used for sound logic later
var scene_enabled = true

const play_scene_path = "res://overworld/level_maps/red_town.tscn"
const play_cutscene_path = "res://cinematic/intro/intro.tscn"

@export var play_scene = preload(play_scene_path) :
	get:
		return play_scene
	set( value ):
		if value is PackedScene:
			play_scene = value
		elif value is String and value.contains("res://"):
			play_scene = load(value)
		elif value == null:
			play_scene = null
		else:
			play_scene = get_node(value)

@export var play_cutscene = preload(play_cutscene_path) :
	get:
		return play_cutscene
	set( value ):
		if value is PackedScene:
			play_cutscene = value
		elif value is String and value.contains("res://"):
			play_cutscene = load(value)
		elif value == null:
			play_cutscene = null
		else:
			play_cutscene = get_node(value)

@export var options_menu = preload("res://menu/options_menu.tscn")
@export var credits_menu = preload("res://menu/options_menu.tscn")

func _ready():
	
	## The following line SHOULD NOT be commented out... however...
	## ... to debug more efficiently, we will be ignoring this ominous warning.
	#GlobalDatabase.fetch_save_to_stage()
	GlobalRuntime.scene_manager.append_preload_map( play_scene_path )
	
	pass


func _on_play_pressed():
	if scene_enabled:
		
		
		GlobalRuntime.scene_manager.mount_cinematic(play_cutscene.instantiate());
		#GlobalRuntime.switch_to_interface( SceneManager.InterfaceOptions.ACTIVITY );
		
		GlobalRuntime.clean_up_descent( self )
		
		if GlobalDatabase.can_recover_last_state():
			print( "can recover, I think!" )
			await GlobalDatabase.save_keyval("test_worked;(&)\\", true)
			print(GlobalDatabase.load_keyval("test_worked;(&)\\"))
			GlobalDatabase.recover_last_state()
		else:
			print( "cannot recover..." )
		
			if play_scene == null:
				GlobalRuntime.scene_manager.change_map_from_path( play_scene_path )
			else:
				GlobalRuntime.scene_manager.change_map( play_scene )
		queue_free()
	pass


func _on_options_pressed():
	#GlobalRuntime.clean_up_descent( self )
	#replace_by(  options_menu.instantiate()  )
	#queue_free()
	pass


func _on_connection_pressed():
	pass


func _on_quit_pressed():
	get_tree().quit()


func _on_credits_pressed():
	if scene_enabled:
		GlobalRuntime.activity_root_node.add_child( credits_menu.instantiate() )
		scene_enabled = false
