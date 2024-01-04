@tool
extends Area2D

const granularity := 1
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
		length = len 
		if is_ready:
			_update_size()
@onready var collision = $Collision
@onready var sprite_left = $CornerL
@onready var sprite_side = $Side
var sprite_side_x = 1.0#0.036
var sprite_right_x = 1.0#0.018
@onready var sprite_right = $CornerR
@export var is_ready := false


func _ready():
	is_ready = true
	_update_size()
	pass


func _update_size():
	collision.shape.size.x = length * GlobalRuntime.DEFAULT_TILE_SIZE
	sprite_side.region_rect.size.x = int( floor(sprite_side_x * (length-1) ) * GlobalRuntime.DEFAULT_TILE_SIZE )
	print("update spriteside scalex ~ ", sprite_side_x * length)
	sprite_side.position.x = (length * GlobalRuntime.DEFAULT_TILE_SIZE)/2 
	sprite_right.position.x = ( (length - (sprite_right_x/2) ) * GlobalRuntime.DEFAULT_TILE_SIZE)
	collision.position.x = (length * GlobalRuntime.DEFAULT_TILE_SIZE)/2 
	
	self.rotation = Vector2(0,1).angle_to( pointing_direction )
	
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
			
			if is_inside_tree():
				move_tween = create_tween()
				if move_tween != null:
					move_tween.tween_property(area, "global_position", \
						new_position , \
						1/area.move_speed ).set_trans(Tween.TRANS_LINEAR)
					await move_tween.finished
				
				(area as Gamepiece).move_to_target( new_position )
				area.resync_position()
		area.is_paused = pidgeonhole_gp_lock
