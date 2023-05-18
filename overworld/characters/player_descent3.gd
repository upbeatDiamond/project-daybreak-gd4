extends CharacterBody2D

# As the name implies, this is the 3rd player attempt, 
# and the script may be recycled into new lineages.
# The code is derived from the Arkeve lineage, but is branched off due 
# to imminent substantial reworking.
# Paradoxically, it contains more Arkeve stuff, but also less.
# Do you know why they call it the scooping room?
# Because, dummy, it's where they keep the scooper.
# You need the scooper to scoop out the bad stuff to put more stuff in its place



signal player_moving_signal
signal player_stopped_signal
signal player_entering_door_signal
signal player_entered_door_signal


var player_speed:float
@export var walk_speed = 5.0
@export var jump_speed = 5.0
@export var run_speed = 12.0
const TILE_SIZE = 16

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

# Should be one of: x, y, z, or n. (Updown, Leftright, Inout, and Null)
var next_taxicab_direction = 'n' 

var is_moving = false;
var is_running = false
var input_direction = Vector2(0,0);
var facing_direction = Vector2(0,0);
var initial_position = Vector2(0,0);	# At start of movement
var resting_position = Vector2(0,0);	# At end of movement
var proportion_to_next_tile = 0.0;

func _ready():
	is_moving = false
	$GFX/Sprite.visible = true
	initial_position = position
	animation_tree.active = true
	update_anim_tree()





func _physics_process(delta):
	if GlobalRuntime.gameworld_input_stopped:
		return
	elif is_moving == false:
		process_movement_input()
	elif input_direction != Vector2.ZERO:
		animation_state.travel("Walk")
		move(delta);
	else:
		is_moving = false;
		update_anim_tree()





func process_movement_input():

	input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if input_direction != facing_direction:
		if (input_direction.x != 0) && (input_direction.y != 0) && (input_direction != Vector2.ZERO):
			input_direction = facing_direction;
	
	facing_direction = input_direction;
			
	if( input_direction.y != 0 && input_direction.x != 0 ):
		if (next_taxicab_direction == 'n' || next_taxicab_direction == 'x'):
			input_direction.x = 0
			next_taxicab_direction = 'y'
		else: #if (nextTaxicabDirection == 'y'):
			input_direction.y = 0
			next_taxicab_direction = 'x'

	if input_direction != Vector2.ZERO:
		initial_position = collision.position
		is_moving = true
		is_running = Input.is_action_pressed("ui_fast")
		if is_running:
			player_speed = run_speed
		else:
			player_speed = walk_speed
		update_anim_tree()


func entered_door():
	emit_signal("player_entered_door_signal")


func move(delta):

	var desired_step: Vector2 = input_direction * TILE_SIZE / 2
	ray.target_position = desired_step
	ray.force_raycast_update()
	
	ledge_ray.target_position = desired_step
	ledge_ray.force_raycast_update()
	door_ray.target_position = desired_step
	door_ray.force_raycast_update()
	
	
	if door_ray.is_colliding():
		if proportion_to_next_tile == 0.0:
			emit_signal("player_entering_door_signal")
		proportion_to_next_tile += walk_speed + delta
		if proportion_to_next_tile >= 1.0:
			player_gfx.position = initial_position + (input_direction * TILE_SIZE) 
			proportion_to_next_tile = 0.0
			
			is_moving = false
			GlobalRuntime.gameworld_input_stopped = true
			$AnimationPlayer.play("Disappear")
			emit_signal("player_entered_door_signal")
			
		else:
			player_gfx.position = initial_position + (TILE_SIZE * (input_direction * proportion_to_next_tile))
			
	elif !ray.is_colliding():
		if proportion_to_next_tile == 0:
			emit_signal("player_moving_signal")
			position = initial_position
			resting_position = (2*desired_step) + initial_position
			collision.position = resting_position
		proportion_to_next_tile += player_speed * delta
		if proportion_to_next_tile >= 1.0:
			# position = initial_position + (TILE_SIZE + input_direction)
			player_gfx.position = Vector2(initial_position.x + (TILE_SIZE * input_direction.x), initial_position.y + (TILE_SIZE * input_direction.y))
			proportion_to_next_tile = 0.0
			initial_position = resting_position
			is_moving = false
			#collision.position = player_gfx.position
			emit_signal("player_stopped_signal")
			input_direction.x = 0
			input_direction.y = 0
		else:
			player_gfx.position = initial_position + (TILE_SIZE * (input_direction * proportion_to_next_tile))
	else:
		is_moving = false
	
	proportion_to_next_tile += player_speed * delta





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
	
	global_position.x = loci.x + 20
	global_position.y = loci.y + 20
	print("gx %d, gy %d, x %d , y %d" % [global_position.x, global_position.y, loci.x, loci.y])
	visible = true
	
	GlobalRuntime.gameworld_input_stopped = false
	$AnimationPlayer.play("Appear")
