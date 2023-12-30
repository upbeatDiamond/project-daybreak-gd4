extends Node

var gamepiece : Gamepiece
var INPUT_COOLDOWN_DEFAULT:float = 6.5;
var input_cooldown := 0.0

func _ready() -> void:
	#set_physics_process(false)
	update_configuration_warnings()
	
	gamepiece = self.get_parent() as Gamepiece
	
	if not Engine.is_editor_hint():
		assert(gamepiece, "Gamepiece '%s' must be a child of a Gamepiece to function! Is '%s'" % [name, get_parent().get_class()] )
		pass
	#set_physics_process(true)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not get_parent() is Gamepiece:
		warnings.append("Controller must be a child of a Gamepiece to function!")
	
	return warnings

func _process(_delta):
	if gamepiece.is_node_ready():
		gamepiece.umid = 0
	#if gamepiece != null:
	#	set_physics_process(true);
	#print( "controller thinks gp = %d", gamepiece )
#	pass

func _physics_process(_delta):
	if GlobalRuntime.gameworld_input_stopped || gamepiece.is_paused:
		return
	elif gamepiece.move_queue.size() <= 1 && gamepiece.is_moving == false && input_cooldown <= 0: #:
		handle_movement_input()
	
	#if Input.is_action_pressed("menu"):
		#GlobalRuntime.scene_manager.player_menu.Control.visible = !GlobalRuntime.scene_manager.player_menu.Control.visible
		#print( str(InputMap.action_get_events("menu")[0]) )
	
	
	
	if input_cooldown > 0:
		input_cooldown -= _delta
	#print( "controller thinks moving = %d", gamepiece.is_moving )


func handle_movement_input():
	if !gamepiece.is_paused:
		var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
		# This section deals with some diagonal inputs cotextually
		if input_direction != gamepiece.facing_direction:
			if (input_direction.x != 0) && (input_direction.y != 0) && (input_direction != Vector2.ZERO):
				input_direction = gamepiece.facing_direction;
				pass
		
		var movement := Movement.new( input_direction )
		
		gamepiece.facing_direction = input_direction;
		
		var is_running = Input.is_action_pressed("ui_fast")
		if is_running:
			movement.method = gamepiece.TraversalMode.RUNNING
		elif Vector2i(gamepiece.facing_direction.x, gamepiece.facing_direction.y) != movement.to_facing_vector2i():
			movement.method = gamepiece.TraversalMode.STANDING
			input_cooldown = INPUT_COOLDOWN_DEFAULT
		else:
			movement.method = gamepiece.TraversalMode.WALKING
		
		if input_direction != Vector2.ZERO:
			gamepiece.queue_movement( movement )
			gamepiece.update_anim_tree()
		
		#if Input.is_action_pressed("debug_summon"):
		#	pass


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
	
	pass
