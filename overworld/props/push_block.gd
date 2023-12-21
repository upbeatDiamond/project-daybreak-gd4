extends Area2D
# This should be an instance or child of a gametoken

@onready var block_ray = $PushCollider/PushRay
@onready var collision = $PushCollider
@onready var gfx = $PushSprite

var move_speed = 2.0
var cooling_down = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	cooling_down = false
	pass

func _physics_process(delta):
	cooling_down = false

func run_event( gamepiece:Gamepiece ):
	
	var pidgeonhole_gp_lock := false
	
	if !cooling_down:
		cooling_down = true
		pidgeonhole_gp_lock = gamepiece.is_paused
		gamepiece.is_paused = true
		# get gamepiece's relative position and/or raycast
		# copy this to raycast to a new position
		var direction = (global_position - gamepiece.global_position).normalized()
		block_ray.target_position = block_ray.position+(direction*GlobalRuntime.DEFAULT_TILE_SIZE)
		block_ray.force_raycast_update()
		
		print("event caught! on... PushBlock!")
		
		var move_tween
		
		# If valid, move there
		if !block_ray.is_colliding():
			
			print(str( "block ray not colliding!", direction) )
			
			var new_position = collision.global_position+(direction*GlobalRuntime.DEFAULT_TILE_SIZE)
			new_position = GlobalRuntime.snap_to_grid_center_f( new_position )
			
			collision.global_position = new_position
			
			if is_inside_tree():
				move_tween = create_tween()
				if move_tween != null:
					move_tween.tween_property(gfx, "global_position", \
						new_position , \
						1/move_speed ).set_trans(Tween.TRANS_LINEAR)
					await move_tween.finished
			
			print(str( new_position, " ~ pushing to" ) )
			#
			resync_position()
		
		gamepiece.is_paused = pidgeonhole_gp_lock 
	# If invalid b/c gamepiece, push gamepiece (parallel, else perpendicular)
		# If gamepiece cannot be pushed, swap with gamepiece
	# If any other intrusion, do not allow push
	
	pass

func resync_position():
	var collision_gp = collision.global_position
	var gfx_gp = gfx.global_position
	
	self.global_position = GlobalRuntime.snap_to_grid_corner_f(collision_gp)
	collision.global_position = collision_gp
	gfx.global_position = gfx_gp
	pass

func _on_area_entered(area):
	if area is Gamepiece or area.is_in_group("gamepiece"):
		#area.set_teleport(target_position, target_facing, map, target_anchor_name)
		run_event( area )
	pass # Replace with function body.
