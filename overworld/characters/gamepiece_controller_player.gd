extends Node

var gamepiece : Gamepiece
var INPUT_COOLDOWN_DEFAULT:float = 6.5;
var input_cooldown := 0.0
@onready var navigation_agent_2d : NavigationAgent2D
var is_rendered := false

func _ready() -> void:
	if gamepiece == null:
		gamepiece = get_parent()
	print("GPC: I think I'm at ", gamepiece.current_position, "")
	update_configuration_warnings()
	
	gamepiece = self.get_parent() as Gamepiece
	
	if not Engine.is_editor_hint():
		assert(gamepiece, "Gamepiece '%s' must be a child of a Gamepiece to function! Is '%s'" 
			% [name, get_parent().get_class()] )


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not get_parent() is Gamepiece:
		warnings.append("Controller must be a child of a Gamepiece to function!")
	return warnings


func _process(_delta):
	#super._process(_delta)
	if gamepiece.is_node_ready():
		gamepiece.umid = 0
		if not is_rendered:
			gamepiece.find_child("SpriteAccent").material.set_shader_parameter("palette", load("res://assets/textures/monsters/overworld/human/human_palette_hair_common.png"))
			gamepiece.find_child("SpriteBase").material.set_shader_parameter("palette", load("res://assets/textures/monsters/overworld/human/human_palette_common.png"))
			is_rendered = true
	#print( "controller thinks gp = %d", gamepiece )


func _physics_process(_delta):
	if GlobalRuntime.gameworld_input_stopped || gamepiece.is_paused:
		return
	elif gamepiece.move_queue.size() <= 1 && gamepiece.is_moving == false && input_cooldown <= 0:
		handle_movement_input()
	
	if input_cooldown > 0:
		input_cooldown -= _delta
	#print( "controller thinks moving = %d", gamepiece.is_moving )


func handle_movement_input():
	if !gamepiece.is_paused and !GlobalRuntime.gameworld_input_stopped:
		var input_direction = Input.get_vector("player_left", "player_right", "player_up", "player_down")
		
		if input_direction == Vector2.ZERO:
			return
		
		# This section deals with some diagonal inputs contextually
		if (input_direction.x != 0) && (input_direction.y != 0) && (input_direction != Vector2.ZERO):
			input_direction = gamepiece.facing_direction;
		
		var movement := Movement.new( input_direction )
		
		gamepiece.facing_direction = input_direction;
		
		var is_running = Input.is_action_pressed("ui_fast")
		if is_running:
			movement.method = gamepiece.TraversalMode.RUNNING
		elif Vector2i(gamepiece.facing_direction) != movement.to_facing_vector2i():
			movement.method = gamepiece.TraversalMode.STANDING
			input_cooldown = INPUT_COOLDOWN_DEFAULT
		else:
			movement.method = gamepiece.TraversalMode.WALKING
		
		if input_direction != Vector2.ZERO:
			gamepiece.facing_direction = input_direction;
			gamepiece.position_stabilized = true
			gamepiece.queue_movement( movement )
			gamepiece.update_anim_tree()
			print("GPC: I think I'm at ", gamepiece.current_position, "")


func handle_map_change( map:String, silent:bool=false ):
	var was_paused = gamepiece.is_paused
	gamepiece.is_paused = true
	
	if !silent:
		print("not silent warp!")
		await GlobalRuntime.scene_manager.fade_to_black()
	
	if GlobalRuntime.scene_manager.get_map_index(map) != null:
		GlobalGamepieceTransfer.submit_gamepiece( gamepiece, \
			GlobalRuntime.scene_manager.get_map_index(map) )
		GlobalRuntime.scene_manager.change_map_from_path(map)
	
	return was_paused


func finalize_map_change( was_paused, silent ):
	if !silent:
		GlobalRuntime.scene_manager.fade_in()
	
	gamepiece.traversal_mode = Gamepiece.TraversalMode.STANDING
	gamepiece.update_anim_tree()
	gamepiece.is_paused = was_paused
	
	print(GlobalRuntime.scene_manager.get_overworld_root(), \
	GlobalRuntime.scene_manager.get_overworld_root().scene_file_path)
	
	var map = (GlobalRuntime.scene_manager.get_overworld_root() as LevelMap)
	
	GlobalDatabase.save_level_map( map )
	
	gamepiece.position_stabilized = true
	
	# Save to preserve at least current position and facing direction
	GlobalDatabase.save_gamepiece( gamepiece )
	pass
