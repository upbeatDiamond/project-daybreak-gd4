#extends Node
extends NavigationAgent2D
# replace with references to NavigationServer2D ...
# ... and merge into a base GamepieceController


var nav_parent : Gamepiece
const TILE_SIZE_VECTOR = Vector2(GlobalRuntime.DEFAULT_TILE_SIZE, GlobalRuntime.DEFAULT_TILE_SIZE)

func auto_walk_to_point( target:Vector2 ):
	target_position = GlobalRuntime.snap_to_grid_center_f( target )
	# target_desired_distance = GlobalRuntime.DEFAULT_TILE_SIZE
	
	var next_subtarget = GlobalRuntime.snap_to_grid_center_f( get_next_path_position() )
	var has_moved_valid = true # Inverse of: Has 'this' movement been invalidated yet?
	var projected_movement : Movement
	var projected_move_result : Vector2
	
	while next_subtarget != target_position and next_subtarget != nav_parent.global_position:
		
		has_moved_valid = true
		var dir_vector = next_subtarget - nav_parent.global_position
		
		# Find greater abs value of X and Y difference
		# If X is greater (or both equal), then check the X axis for if valid
		if abs(dir_vector.x) >= abs(dir_vector.y) and dir_vector.x != 0:
			# Check if X axis movement is valid
			# If X axis movement is valid, queue the matching X axis movement
			nav_parent.update_rays(Vector2(sign(dir_vector.x)*GlobalRuntime.DEFAULT_TILE_SIZE,0))
			
			if nav_parent.block_ray.is_colliding():
				has_moved_valid = false
			else:
				projected_movement = Movement.new( Vector2(dir_vector.x, 0) )
				nav_parent.queue_movement( projected_movement )
		
		# If Y is greater (or Y != 0 and X invalid), check if Y axis move is valid
		if !has_moved_valid and dir_vector.y != 0:
			# Check if Y axis movement is valid
			# If Y axis movement is valid, queue the matching Y axis movement
			nav_parent.update_rays(Vector2(0,sign(dir_vector.y)*GlobalRuntime.DEFAULT_TILE_SIZE))
			
			if nav_parent.block_ray.is_colliding():
				has_moved_valid = false
			else:
				projected_movement = Movement.new( Vector2(0, dir_vector.y) ) 
				nav_parent.queue_movement( projected_movement )
		
		# If X and Y axis movements are invalid, wait to try again + print.
		if !has_moved_valid:
			# wait a lil bit to see if things move.
			pass
		else:
			projected_move_result = nav_parent.global_position 
			projected_move_result += GlobalRuntime.DEFAULT_TILE_SIZE * projected_movement.to_cell_vector2f()
			projected_move_result = GlobalRuntime.snap_to_grid_center_f( projected_move_result )
			
			# following line is both (1) incomplete and (2) may be incorrect overall.
			await nav_parent.gamepiece_moved.global_endpoint
		
		
		#if nav_parent.global_position
		next_subtarget = GlobalRuntime.snap_to_grid_center_f( get_next_path_position() )
	pass
