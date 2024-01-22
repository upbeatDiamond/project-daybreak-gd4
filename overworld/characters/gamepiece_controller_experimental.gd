extends Node
class_name GamepieceController
# When stabilized and tested, will be the new GamepieceController(Base), which GC.Player inherits

var gamepiece : Gamepiece
var INPUT_COOLDOWN_DEFAULT:float = 6.5;
var input_cooldown := 0.0
var nav_agent : RID
var move_control_mode := MoveControlMode.CONTROLLER

enum MoveControlMode{
	PLAYPAD = 0,	# keylogger playback
	CONTROLLER,		# live key response
	AUTOPATH,		# follow auto_waypoints
}

var auto_waypoints:PackedVector2Array=[]
var auto_current_target:Vector2
var auto_target_position:Vector2


func _init():
	nav_agent = NavigationServer2D.agent_create()
	NavigationServer2D.agent_set_radius( nav_agent, GlobalRuntime.DEFAULT_TILE_SIZE/2.0 )
	NavigationServer2D.agent_set_map( nav_agent, _get_map_rid() )
	_update_nav_agent_position()


func _ready() -> void:
	gamepiece = self.get_parent() as Gamepiece
	
	update_configuration_warnings()
	set_physics_process(true)


func _process(_delta):
	pass


func _physics_process(_delta):
	if GlobalRuntime.gameworld_input_stopped || gamepiece.is_paused:
		return
	elif gamepiece.move_queue.size() <= 1 and gamepiece.is_moving == false \
	and input_cooldown <= 0:
		match move_control_mode:
			MoveControlMode.PLAYPAD:
				move_control_mode = MoveControlMode.CONTROLLER #PLAYPAD not implemented yet
			MoveControlMode.CONTROLLER:
				handle_movement_input()
			MoveControlMode.AUTOPATH:
				handle_movement_auto()
			_:	# If we don't know what the control mode is, then finish the path.
				if auto_waypoints.size() <= 0:
					handle_movement_input()
				else: 
					handle_movement_auto()
	
	if input_cooldown > 0:
		input_cooldown -= _delta


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not get_parent() is Gamepiece:
		warnings.append("Controller must be a child of a Gamepiece to function!")
	
	return warnings


func handle_movement_input():
	assert(false, "Error: handle_movement_input(void) was not implemented!")
	pass


func _guess_nav_agent_position():
	return GlobalRuntime.snap_to_grid_center_f( gamepiece.collision.global_position )
	pass


func assign_target_position( target:Vector2 ):
	auto_target_position = target
	_update_nav_agent_position()
	_regenerate_auto_path_to_target( auto_target_position )


func _update_nav_agent_position():
	var nav_pos = _guess_nav_agent_position()
	NavigationServer2D.agent_set_position( nav_agent, nav_pos )


func queue_auto_path( waypoints:PackedVector2Array ):
	auto_waypoints = waypoints


func _regenerate_auto_path_to_target( target:Vector2 ):
	var path_fix = NavigationServer2D.map_get_path( _get_map_rid(), _guess_nav_agent_position(), \
		GlobalRuntime.snap_to_grid_center_f(target), true )
	queue_auto_path( path_fix )


func _get_map_rid():
	# Please please get RID from the current level map
	return GlobalRuntime.scene_manager.gamepiece_nav_map


func handle_movement_auto():
	
	_update_nav_agent_position()
	
	if auto_current_target != null:
		_auto_walk_to_point( auto_current_target )
	elif !auto_waypoints.is_empty():
		auto_current_target = auto_waypoints[0]
		auto_waypoints.remove_at(0)
		_auto_walk_to_point( auto_current_target )
	else:
		return


func _packed_vector2_pop_front(packed:PackedVector2Array):
	if packed == null or packed.size() <= 0:
		return null
	var ret = packed[0]
	packed.remove_at(0)
	return ret


func _get_next_path_position():
	if auto_current_target == null or \
	(gamepiece.global_position-auto_current_target).length() < GlobalRuntime.DEFAULT_TILE_SIZE/2:
		auto_current_target = _packed_vector2_pop_front(auto_waypoints)
	return auto_current_target


func _auto_walk_to_point( target:Vector2 ):
	_regenerate_auto_path_to_target(target)
	auto_target_position = GlobalRuntime.snap_to_grid_center_f( target )
	_auto_walk_to_next_point()
	pass


func _auto_walk_to_next_point():
	var next_subtarget = _get_next_path_position()
	var has_moved_valid = true # Inverse of: Has 'this' movement been invalidated yet?
	var projected_movement : Movement = Movement.new()
	var projected_move_result : Vector2
	
	if next_subtarget != auto_target_position and next_subtarget != gamepiece.global_position:
		
		has_moved_valid = true
		var dir_vector = next_subtarget - gamepiece.global_position
		
		# Find greater abs value of X and Y difference
		# If X is greater (or both equal), then check the X axis for if valid
		if abs(dir_vector.x) >= abs(dir_vector.y) and dir_vector.x != 0:
			# Check if X axis movement is valid
			# If X axis movement is valid, queue the matching X axis movement
			gamepiece.update_rays(Vector2(sign(dir_vector.x)*GlobalRuntime.DEFAULT_TILE_SIZE,0))
			
			if gamepiece.block_ray.is_colliding():
				has_moved_valid = false
			else:
				projected_movement = Movement.new( Vector2(dir_vector.x, 0) )
				gamepiece.queue_movement( projected_movement )
		
		# If Y is greater (or Y != 0 and X invalid), check if Y axis move is valid
		if !has_moved_valid and dir_vector.y != 0:
			# Check if Y axis movement is valid
			# If Y axis movement is valid, queue the matching Y axis movement
			gamepiece.update_rays(Vector2(0,sign(dir_vector.y)*GlobalRuntime.DEFAULT_TILE_SIZE))
			
			if gamepiece.block_ray.is_colliding():
				has_moved_valid = false
			else:
				projected_movement = Movement.new( Vector2(0, dir_vector.y) ) 
				gamepiece.queue_movement( projected_movement )
		
		# If X and Y axis movements are invalid, wait to try again + print.
		if !has_moved_valid:
			# wait a lil bit to see if things move.
			input_cooldown = INPUT_COOLDOWN_DEFAULT
			pass
	
	projected_move_result = GlobalRuntime.DEFAULT_TILE_SIZE*projected_movement.to_cell_vector2f() \
		+ gamepiece.global_position
	
	return projected_move_result
	pass
