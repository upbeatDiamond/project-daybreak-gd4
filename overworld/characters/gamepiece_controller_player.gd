extends Node

var gamepiece : Gamepiece

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

#func _process(_delta):
	#if gamepiece != null:
	#	set_physics_process(true);
	#print( "controller thinks gp = %d", gamepiece )
#	pass

func _physics_process(_delta):
	if GlobalRuntime.gameworld_input_stopped || gamepiece.is_paused:
		return
	elif gamepiece.move_queue.size() <= 1 && gamepiece.is_moving == false: #:
		handle_movement_input()
	#print( "controller thinks moving = %d", gamepiece.is_moving )


func handle_movement_input():
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if input_direction != gamepiece.facing_direction:
		if (input_direction.x != 0) && (input_direction.y != 0) && (input_direction != Vector2.ZERO):
			input_direction = gamepiece.facing_direction;
			pass
	
	gamepiece.facing_direction = input_direction;
	
	var is_running = Input.is_action_pressed("ui_fast")
	if is_running:
		gamepiece.traversal_mode = gamepiece.TraversalMode.RUNNING
	else:
		gamepiece.traversal_mode = gamepiece.TraversalMode.WALKING
	
	if input_direction != Vector2.ZERO:
		gamepiece.queue_move( input_direction )
		gamepiece.update_anim_tree()
	
	if Input.is_action_pressed("debug_summon"):
		pass


func handle_map_change( map:String ):
	
	#animation_tree.set("parameters/Idle/blend_position", direction)
	#animation_tree.set("parameters/Walk/blend_position", direction)
	
	#animation_state.travel("Idle")
	
	GlobalGamepieceTransfer.submit_gamepiece( gamepiece, GlobalRuntime.scene_manager.get_map_index(map) )
	GlobalRuntime.scene_manager.change_map(map)
	
	#visible = true
	
	#GlobalRuntime.gameworld_input_stopped = false
	#$AnimationPlayer.play("Appear")
	
	pass
