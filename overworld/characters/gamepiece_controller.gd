extends Node
class_name GamepieceController

var gamepiece : Gamepiece
const INPUT_COOLDOWN_DEFAULT:float = 0.25;
var input_cooldown := 0.0
@onready var navigation_agent_2d : NavigationAgent2D
var is_rendered := false
var target_position = Vector2(0,0)

var nav_mode := NavigationMode.KEYBOARD_LOCAL
const MOVE_QUEUE_CAPACITY := 3

enum NavigationMode{
	KEYBOARD_LOCAL = 0,
	KEYBOARD_STREAMED,
	AUTONAV
}



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
	if gamepiece.is_node_ready():
		if not is_rendered and gamepiece.umid == 0:
			var palette_base_path = str("res://assets/textures/monsters/overworld/human/human_palette_",GlobalDatabase.load_keyval("player_sprite_base_palette"),".png")
			var palette_accent_path = str("res://assets/textures/monsters/overworld/human/human_palette_hair_",GlobalDatabase.load_keyval("player_sprite_accent_palette"),".png")
			if FileAccess.file_exists(palette_accent_path):
				gamepiece.find_child("SpriteAccent").material.set_shader_parameter("palette", load(palette_accent_path))
			if FileAccess.file_exists(palette_base_path):
				gamepiece.find_child("SpriteBase").material.set_shader_parameter("palette", load(palette_base_path))
			is_rendered = true


func _physics_process(_delta):
	if nav_mode == NavigationMode.KEYBOARD_LOCAL and \
		(GlobalState.is_gamepiece_input_ignored() or gamepiece.is_paused):
		return
	elif gamepiece.move_queue.size() <= 1 && gamepiece.is_moving == false && input_cooldown <= 0:
		handle_movement_input()
	
	if input_cooldown > 0:
		input_cooldown -= _delta
	#print( "controller thinks moving = %d", gamepiece.is_moving )


func _autonav_next_move() -> Vector2:
	if navigation_agent_2d == null:
		navigation_agent_2d = NavigationAgent2D.new()
		self.get_parent().add_child(navigation_agent_2d)
	elif navigation_agent_2d.get_parent() != self.get_parent():
		navigation_agent_2d.reparent(self.get_parent())
	
	navigation_agent_2d.target_position = target_position
	
	@warning_ignore("integer_division")
	if abs(get_parent().global_position.x - target_position.x) <= GlobalTools.DEFAULT_TILE_SIZE/2 and\
		abs(get_parent().global_position.y - target_position.y) <= GlobalTools.DEFAULT_TILE_SIZE/2 :
		nav_mode = NavigationMode.KEYBOARD_LOCAL
		return Vector2.ZERO
	
	var current_agent_position = gamepiece.global_position
	var next_path_position = navigation_agent_2d.get_next_path_position()
	var new_direction = current_agent_position.direction_to(next_path_position)
	
	print(new_direction, " % ", target_position)
	
	## Quick patch, because sometimes the navigation agent gets stuck on corners?
	var bonk = await gamepiece._peek_exterior_collision(new_direction * gamepiece.vector2_from_facing())
	if bonk:
		new_direction = new_direction * gamepiece.vector2_from_facing()
	
	return new_direction


func _handle_movement_direction() -> Vector2:
	match nav_mode:
		NavigationMode.KEYBOARD_LOCAL:
			if gamepiece.move_queue.size() > MOVE_QUEUE_CAPACITY:
				gamepiece.move_queue = gamepiece.move_queue.slice(gamepiece.move_queue.size() - MOVE_QUEUE_CAPACITY)
			if gamepiece.treat_as_player:
				return Input.get_vector("player_left", "player_right", "player_up", "player_down")
			return Vector2(0,0)
		NavigationMode.AUTONAV:
			var autonav  = await _autonav_next_move()
			return autonav
	return Vector2.ZERO


func _handle_movement_running() -> bool:
	match nav_mode:
		NavigationMode.KEYBOARD_LOCAL:
			return Input.is_action_pressed("ui_fast")
		NavigationMode.AUTONAV:
			return false
	return false


func set_autonav(target_pos:Vector2):
	target_position = target_pos
	nav_mode = NavigationMode.AUTONAV


func handle_movement_input():
	var input_direction = await _handle_movement_direction()
	
	if input_direction == Vector2.ZERO:
		return
	
	## This section deals with some diagonal inputs contextually
	## If x and y are not equal, choose the greater.
	## Else, change direction so the character moves zig-zag
	## Else, follow the direction the character is facing, 
	## if X and Y are 0 or NaN.
	
	if (abs(input_direction.x) > abs(input_direction.y)):
		input_direction = Vector2(sign(input_direction.x), 0)
	elif (abs(input_direction.x) < abs(input_direction.y)):
		input_direction = Vector2(0, sign(input_direction.y))
	elif ( gamepiece.vector2_from_facing().x > 0 ):
		input_direction = Vector2(0, sign(input_direction.y))
	elif ( gamepiece.vector2_from_facing().y > 0 ):
		input_direction = Vector2(sign(input_direction.x), 0)
	
	## Zig-zag?
	if (input_direction.x != 0) && (input_direction.y != 0) && (input_direction != Vector2.ZERO):
		input_direction = Vector2( sign(input_direction.x)*(gamepiece.vector2_from_facing().y), 
								sign(input_direction.y)*(gamepiece.vector2_from_facing().x));
	
	print("GPC: Input direction = ", input_direction)
	var movement := Movement.new( input_direction )
	
	gamepiece.facing_from_vector2(input_direction);
	
	var is_running = _handle_movement_running()
	if is_running:
		movement.method = gamepiece.TraversalMode.RUNNING
	elif gamepiece.vector2i_from_facing() != movement.to_facing_vector2i():
		movement.method = gamepiece.TraversalMode.STANDING
		input_cooldown = INPUT_COOLDOWN_DEFAULT
	else:
		movement.method = gamepiece.TraversalMode.WALKING
	
	if input_direction != Vector2.ZERO:
		gamepiece.facing_from_vector2(input_direction);
		gamepiece.position_stabilized = true
		gamepiece.queue_movement( movement )
		gamepiece.update_anim_tree()
		print("GPC: I think I, ", gamepiece.tag, 
				" am at ", gamepiece.current_position, "")


func finish_teleport(silent:bool=false):
	_finish_teleport_local(silent)


func _start_teleport_local(loci: Vector2i, direction: Vector2i, _silent:=false):
	gamepiece.shift_to_target(loci)
	print("teleport: gx %d, gy %d, x %d, y %d"%[gamepiece.global_position.x,gamepiece.global_position.y,loci.x,loci.y])
	gamepiece.set_facing_from_vector2(direction)
	gamepiece._snap_camera_to_protag()


## When touching a teleport, the chain of function calls should end up here.
func _start_teleport_map( map:String, anchor_name:String="", silent:bool=false ):
	## Parse and then save where the gamepiece ought to be.
	var target_map_id = GlobalDatabase.get_map_index(map)
	var anchor_coord = GlobalDatabase.get_anchor_coord(target_map_id, anchor_name)
	var current_map_id = LevelMap.guess_current_map()
	print("anchor detail: ", anchor_coord, " :+ name: ", anchor_name)
	
	LevelMap.save_gamepiece(gamepiece, target_map_id, anchor_coord, target_map_id )
	
	## If the teleport position may be visible, move it properly.
	## Else, delete it, and make sure we are on the map the player is in
	if current_map_id == target_map_id:
		_start_teleport_local(anchor_coord, Vector2i.ZERO, silent)
	else:
		gamepiece.pack_up()
		if gamepiece.treat_as_player:
			GlobalState.scene_manager.change_map_from_path(map)


## When switching within the same map
func _finish_teleport_local(silent:bool=false):
	
	if !silent:
		GlobalState.scene_manager.fade_in()
	
	gamepiece.traversal_mode = Gamepiece.TraversalMode.STANDING
	gamepiece.update_anim_tree()
	
	print(GlobalState.scene_manager.get_overworld_root(), \
	GlobalState.scene_manager.get_overworld_root().scene_file_path)
	
	pass
