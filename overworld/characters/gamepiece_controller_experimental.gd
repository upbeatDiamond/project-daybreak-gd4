extends Node
#extends NavigationAgent2D
# replace with references to NavigationServer2D ...
# ... and merge into a base GamepieceController


var gamepiece : Gamepiece
var INPUT_COOLDOWN_DEFAULT:float = 6.5;
var input_cooldown := 0.0
var nav_agent : RID

enum MoveControlMode{
	PLAYPAD = 0,	# keylogger playback
	CONTROLLER,		# live key response
	AUTOPATH,		# follow auto_waypoints
}

var auto_waypoints:PackedVector2Array=[]
var auto_current_target:Vector2
var auto_target_position:Vector2

#var gamepiece : Gamepiece
#const TILE_SIZE_VECTOR = Vector2(GlobalRuntime.DEFAULT_TILE_SIZE, GlobalRuntime.DEFAULT_TILE_SIZE)

#var gamepiece : Gamepiece

func _init():
	nav_agent = NavigationServer2D.agent_create()
	NavigationServer2D.agent_set_radius( nav_agent, GlobalRuntime.DEFAULT_TILE_SIZE/2.0 )
	NavigationServer2D.agent_set_position( nav_agent, gamepiece.collision.global_position )

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
	elif gamepiece.move_queue.size() <= 1 and gamepiece.is_moving == false \
	and input_cooldown <= 0:
		if auto_waypoints.size() <= 0:
			handle_movement_input()
		else: 
			handle_movement_auto()

func handle_movement_input():
	pass

func queue_auto_path( waypoints:PackedVector2Array ):
	
	auto_waypoints = waypoints
	
	pass

func handle_movement_auto():
	
	NavigationServer2D.agent_set_position( nav_agent, gamepiece.collision.global_position )
	
	if auto_current_target != null:
		_auto_walk_to_point( auto_current_target )
	elif !auto_waypoints.is_empty():
		auto_current_target = auto_waypoints[0]
		auto_waypoints.remove_at(0)
		_auto_walk_to_point( auto_current_target )
	
	pass

#func _get_next_path_position():
	#
	#if auto_current_target != null and \
	#(gamepiece.global_position - auto_current_target).length() < GlobalRuntime.DEFAULT_TILE_SIZE / 2:
		#pass
	#pass

func _auto_walk_to_point( target:Vector2 ) -> Vector2:
	auto_target_position = GlobalRuntime.snap_to_grid_center_f( target )
	
	var next_subtarget = auto_target_position #GlobalRuntime.snap_to_grid_center_f( get_next_path_position() )
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
		
		#if gamepiece.global_position
		#next_subtarget = GlobalRuntime.snap_to_grid_center_f( get_next_path_position() )
	
	projected_move_result = GlobalRuntime.DEFAULT_TILE_SIZE*projected_movement.to_cell_vector2f() \
		+ gamepiece.global_position
	
	return projected_move_result
	pass
