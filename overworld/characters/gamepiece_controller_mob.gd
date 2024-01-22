extends Node

var gamepiece : Gamepiece
#var dstar_agent : DStarLite
#var board : TileMap
#@export var dstar_mask := 3

func _ready() -> void:
	
	#for c in GlobalRuntime.scene_root_node.get_children():
	#	c = c as TileMap
	#	if (c != null and (board == null || c.name.to_lower() == "board")  ):
	#		board = c
	#dstar_agent = DStarLite.new( board, dstar_mask )
	gamepiece = self.get_parent() as Gamepiece
	#dstar_agent.new_path( (gamepiece.position) / GlobalRuntime.DEFAULT_TILE_SIZE, gamepiece.target_position / GlobalRuntime.DEFAULT_TILE_SIZE )
	
	update_configuration_warnings()
	set_physics_process(true)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not get_parent() is Gamepiece:
		warnings.append("Controller must be a child of a Gamepiece to function!")
	
	return warnings


func _physics_process(delta):
	
	#print( str("I think my collision is offset from ", gamepiece.position ," by ", gamepiece.collision.position, " and gfx by ", gamepiece.gfx.position) )
	
	if GlobalRuntime.gameworld_input_stopped || gamepiece.is_paused:
		return
	elif gamepiece.is_moving == false:
		#if dstar_agent.load_next_cell() != Vector2i(gamepiece.target_position.x, gamepiece.target_position.y):
		pass#handle_movement_input()

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
