@tool
extends Area2D

const granularity := 1
const jump_height := 2.0 # Height expressed in number of tiles; float in case half-tiles are needed
const landing_dust_effect = 0 #preload("")
@export var pointing_direction := Vector2(0,1):
	set(dir):
		if abs(dir.x) > abs(dir.y):
			dir.y = 0
		elif abs(dir.y) > abs(dir.x):
			dir.x = 0
		else:
			return
		dir = dir.normalized()
		if dir != Vector2.ZERO:
			pointing_direction = dir.snapped( Vector2(1,1) )
		if is_ready:
			_update_size()

@export var length := 1:
	set(len):
		length = abs(len)
		if is_ready:
			_update_size()
@onready var collision = $Collision
@onready var sprite_left = $CornerL
@onready var sprite_side = $Side
var sprite_side_x = 1.0#0.036
var sprite_right_x = 1.0#0.018
@onready var sprite_right = $CornerR
@export var is_ready := false

var current_pos_offset := Vector2(0,0)

func _ready():
	is_ready = true
	_update_size()
	pass


func _update_size():
	
	# reset offset
	var children = get_children()
	for child in children:
		child.position -= current_pos_offset
	
	collision.shape.size.x = length * GlobalRuntime.DEFAULT_TILE_SIZE
	sprite_side.region_rect.size.x = int( floor(sprite_side_x * (length-1) ) * GlobalRuntime.DEFAULT_TILE_SIZE )
	#print("update spriteside scalex ~ ", sprite_side_x * length)
	@warning_ignore( "integer_division" )
	sprite_side.position.x = (length * GlobalRuntime.DEFAULT_TILE_SIZE)/2 
	sprite_right.position.x = ( (length - (sprite_right_x/2) ) * GlobalRuntime.DEFAULT_TILE_SIZE)
	@warning_ignore( "integer_division" )
	collision.position.x = (length * GlobalRuntime.DEFAULT_TILE_SIZE)/2 
	
	self.rotation = Vector2(0,1).angle_to( pointing_direction )
	
	match pointing_direction:
		Vector2.DOWN:
			current_pos_offset = Vector2(0,0) * GlobalRuntime.DEFAULT_TILE_SIZE
		Vector2.UP:
			current_pos_offset = Vector2(-1,-1) * GlobalRuntime.DEFAULT_TILE_SIZE
		Vector2.LEFT:
			current_pos_offset = Vector2(0,-1) * GlobalRuntime.DEFAULT_TILE_SIZE
		Vector2.RIGHT:
			current_pos_offset = Vector2(-1,0) * GlobalRuntime.DEFAULT_TILE_SIZE
	
	# set offset, so the first tile's top-left corner is always in the same spot, within float err
	for child in children:
		child.position += current_pos_offset
	pass


func run_event( area ):
	if area is Gamepiece or area.is_in_group("gamepiece"):
		var move_tween
		var pidgeonhole_gp_lock = area.is_paused
		area.is_paused = true
		area.move_tween.kill()
		
		if pointing_direction == area.facing_direction:
			
			var new_position = area.global_position + \
				2*(pointing_direction * GlobalRuntime.DEFAULT_TILE_SIZE)
			new_position = GlobalRuntime.snap_to_grid_corner_f( new_position )
			print("pointeing direction ~ ", pointing_direction)
			
			var new_pos_collision = GlobalRuntime.snap_to_grid_center_f( new_position )
			area.collision.global_position = new_pos_collision
			
			if is_inside_tree():
				move_tween = create_tween()
				if move_tween != null:
					move_tween.pause()
					move_tween.tween_method( _parabola_jump.bind(area.global_position, new_position, area.gfx), 0.0, 1.0, 2/area.jump_speed)
					move_tween.set_process_mode( Tween.TWEEN_PROCESS_IDLE )
					move_tween.play()
					await move_tween.finished
				
				area.resync_position()
		area.is_paused = pidgeonhole_gp_lock

func _parabola_jump( progress, start, end, thing ) -> Vector2:
	var h = jump_height * GlobalRuntime.DEFAULT_TILE_SIZE
	progress = clamp(progress, 0.0, 1.0)
	
	# Remember, high Y on Desmos is 'up', but when porting to Godot, Y = 'down', thus...
	# ... subtracting rather than adding the Y-offset
	var point = ((1-progress) * start) + (progress * end) - \
		Vector2( 0, h*(-1*pow(progress - 0.5, 2) + 0.25) )
	thing.global_position = point
	#print("That's what the point of damascus ~ ", point)
	return point
