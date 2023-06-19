extends Area2D

# As the name implies, this is the 4th player attempt, 
# and the script may be recycled into new lineages.
# The code uses many pieces from the Arkeve lineage, but 
# most of it is commented out and will be torn apart and
# welded back together like scrap metal.
# Primarily, this uses https://kidscancode.org/godot_recipes/4.x/2d/grid_movement/index.html
# The 3.x version's repo is MIT licensed, so as long as the functional
# code here doesn't look too much like anyone elses, I should be fine.
# I think
# idk im not a lawyer


signal player_moving_signal
signal player_stopped_signal
signal player_entering_door_signal
signal player_entered_door_signal


var move_speed:float
@export var walk_speed = 5.0
@export var jump_speed = 5.0
@export var run_speed = 12.0


const TILE_SIZE = 16
var tile_offset = Vector2.ONE * (TILE_SIZE+1)/2 #Vector2.ONE * (TILE_SIZE+1)/2

const LandingDustEffect = preload("res://overworld/landing_dust_effect.tscn")

@onready var animation_tree = $AnimationTree
@onready var animation_state = animation_tree["parameters/playback"]
@onready var ray = $Collision/BlockingRayCast2D
@onready var ledge_ray = $Collision/LedgeRayCast2D
@onready var door_ray = $Collision/DoorRayCast2D
@onready var player_gfx = $GFX
@onready var shadow = $GFX/Shadow
@onready var collision = $Collision

var jumping_over_ledge: bool = false


var is_moving = false;
var is_running = false
var input_direction = Vector2(0,0);
var facing_direction = Vector2(0,0);	# Used for animation state tree
var initial_position = Vector2(0,0);	# At start of total movement
var resting_position = Vector2(0,0);	# At end of total movement, might be unused
var proportion_to_next_tile = 0.0;		# Was "percent_moved_..." but it's not a percentage?
										# ^ might be unused


func snap_to_grid( pos ) -> Vector2:
	var tile_offset = (Vector2.ONE*TILE_SIZE/2)
	return (pos - tile_offset).snapped(Vector2.ONE * TILE_SIZE) + tile_offset
	pass

func _ready():
	is_moving = false
	$GFX/Sprite.visible = true
	#position = position.snapped(Vector2.ONE * TILE_SIZE) + (Vector2.ONE*TILE_SIZE/2)
	snap_to_grid( position )
	#player_gfx.position -= tile_offset
	animation_tree.active = true
	update_anim_tree()


func handle_movement_input():
	input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if input_direction != facing_direction:
		if (input_direction.x != 0) && (input_direction.y != 0) && (input_direction != Vector2.ZERO):
			input_direction = facing_direction;
			pass
	
	facing_direction = input_direction;
	
	is_running = Input.is_action_pressed("ui_fast")
	if is_running:
		move_speed = run_speed
	else:
		move_speed = walk_speed
	
	if input_direction != Vector2.ZERO:
		move()
		update_anim_tree()


func move():
	
	ray.target_position = input_direction * TILE_SIZE
	ray.force_raycast_update()
	if !ray.is_colliding():
		
		var new_position = snap_to_grid( collision.position + input_direction * TILE_SIZE )
		
		collision.position = new_position
		
		var tween = create_tween()
		tween.tween_property(player_gfx, "position",
			new_position - tile_offset, 1.0/move_speed).set_trans(Tween.TRANS_LINEAR)
		is_moving = true
		await tween.finished
		is_moving = false
		
	



func _physics_process(delta):
	if GlobalRuntime.gameworld_input_stopped:
		return
	elif is_moving == false:
		handle_movement_input()







func entered_door():
	emit_signal("player_entered_door_signal")




func update_anim_tree():
	animation_tree.set("parameters/Idle/blend_position", facing_direction)
	animation_tree.set("parameters/Walk/blend_position", facing_direction)
	
	if is_moving == true:
		animation_state.travel("Walk")
	else:
		animation_state.travel("Idle")






func set_spawn(loci: Vector2, direction: Vector2):
	set_teleport(loci, direction)



func set_teleport(loci: Vector2, direction: Vector2):
	is_moving = false
	input_direction = direction
	animation_tree.set("parameters/Idle/blend_position", direction)
	animation_tree.set("parameters/Walk/blend_position", direction)
	
	animation_state.travel("Idle")
	
	loci = snap_to_grid( loci )
	
	global_position.x = floori( loci.x + 0.5 ) # + 20
	global_position.y = floori( loci.y + 0.5 ) # + 20
	print("teleport to gx %d, gy %d, x %d , y %d" % [global_position.x, global_position.y, loci.x, loci.y])
	visible = true
	
	GlobalRuntime.gameworld_input_stopped = false
	$AnimationPlayer.play("Appear")
