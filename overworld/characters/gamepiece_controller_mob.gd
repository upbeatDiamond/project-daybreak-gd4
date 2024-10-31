extends Node

var gamepiece : Gamepiece
var INPUT_COOLDOWN_DEFAULT:float = 6.5;
var input_cooldown := 0.0
@onready var navigation_agent_2d : NavigationAgent2D
var _input_direction_bypass := Vector2(0,0)
var move_control_mode := MoveControlMode.CONTROLLER

var auto_current_target:Vector2
var auto_target_position:Vector2

enum MoveControlMode{
	PLAYPAD = 0,	# keylogger playback
	CONTROLLER,		# live key response
	AUTOPATH,		# follow auto_waypoints
}


func _ready() -> void:
	if gamepiece == null:
		gamepiece = get_parent()
	print("GPCm: I think I'm at ", gamepiece.current_position, "")
	update_configuration_warnings()
	
	gamepiece = self.get_parent() as Gamepiece
	navigation_agent_2d = gamepiece.find_child("NavigationAgent", true)
	
	if not Engine.is_editor_hint():
		assert(gamepiece, "Gamepiece '%s' must be a child of a Gamepiece to function! Is '%s'" 
			% [name, get_parent().get_class()] )
	
	set_physics_process(true)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not get_parent() is Gamepiece:
		warnings.append("Controller must be a child of a Gamepiece to function!")
	return warnings


func _physics_process(_delta):
	
	#print( str("I think my collision is offset from ", gamepiece.position ," by ", gamepiece.collision.position, " and gfx by ", gamepiece.gfx.position) )
	
	if GlobalRuntime.gameworld_input_stopped || gamepiece.is_paused:
		return
	elif gamepiece.move_queue.size() < 1 and gamepiece.is_moving == false \
	and input_cooldown <= 0:
		match move_control_mode:
			MoveControlMode.PLAYPAD:
				move_control_mode = MoveControlMode.CONTROLLER #PLAYPAD not implemented yet
			MoveControlMode.CONTROLLER:
				handle_movement_input()
			#MoveControlMode.AUTOPATH:
				#handle_movement_auto()
				pass
			_:	# If we don't know what the control mode is, then finish the path.
				#if auto_waypoints.size() <= 0:
				handle_movement_input()
				#else: 
					#handle_movement_auto()
				pass
		
	
	if input_cooldown > 0:
		input_cooldown -= _delta
	#print( "controller thinks moving = %d", gamepiece.is_moving )


func handle_movement_input():
	if !gamepiece.is_paused:
		var input_direction = _input_direction_bypass#Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
		if input_direction == Vector2.ZERO:
			return
		
		# This section deals with some diagonal inputs contextually
		# If x and y are not equal, choose the greater.
		# Else, change direction so the character moves zig-zag
		# Else, follow the direction the character is facing, if X and Y are 0 or NaN.
		if (abs(input_direction.x) > abs(input_direction.y)):
			input_direction = Vector2(sign(input_direction.x), 0)
		elif (abs(input_direction.x) < abs(input_direction.y)):
			input_direction = Vector2(0, sign(input_direction.y))
		elif ( abs(gamepiece.facing_direction.x) > 0 ):
			input_direction = Vector2(0, sign(input_direction.y))
		elif ( abs(gamepiece.facing_direction.x) > 0 ):
			input_direction = Vector2(sign(input_direction.x), 0)
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


#func handle_movement_auto():
	#
	#assign_target_position(auto_current_target)
	#
	#if auto_current_target != null:
		#_auto_walk_to_point( auto_current_target )
	#elif !auto_waypoints.is_empty():
		#auto_current_target = auto_waypoints[0]
		#auto_waypoints.remove_at(0)
		#_auto_walk_to_point( auto_current_target )
	#else:
		#return


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


func assign_target_position( target:Vector2 ):
	
	gamepiece.target_position = gamepiece.snap_to_grid( target )
	if gamepiece.position != gamepiece.target_position:
		#dstar_agent.new_path(gamepiece.position, gamepiece.target_position)
		pass
	
	
	pass


#func handle_movement_input():
	##var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#var next_target = dstar_agent.pop_next_cell()
	#var current_cell = Vector2(gamepiece.position.x / GlobalRuntime.DEFAULT_TILE_SIZE, gamepiece.position.y / GlobalRuntime.DEFAULT_TILE_SIZE)
	#var input_direction = Vector2(next_target.x - current_cell.x, next_target.y - current_cell.y)
	#input_direction = input_direction.clamp( Vector2(-1,-1), Vector2(1,1) )
	##if input_direction != gamepiece.facing_direction:
	##	if (input_direction.x != 0) && (input_direction.y != 0) && (input_direction != Vector2.ZERO):
	##		input_direction = gamepiece.facing_direction;
	##		pass
	#
	#gamepiece.facing_direction = input_direction;
	#
	##var is_running = Input.is_action_pressed("ui_fast")
	#var is_running = false
	#if is_running:
		#gamepiece.move_speed = gamepiece.run_speed
	#else:
		#gamepiece.move_speed = gamepiece.walk_speed
	#
	#if input_direction != Vector2.ZERO:
		#gamepiece.queue_move( input_direction )
		#gamepiece.update_anim_tree()
		#
