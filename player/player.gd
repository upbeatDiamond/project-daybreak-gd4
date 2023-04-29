extends CharacterBody2D

@export var move_speed : float = 8.0
const TILE_SIZE = 16

var is_moving = false;
var input_direction;
var facing_direction;
var initial_position = Vector2(0,0)
var percent_moved_to_next_tile = 0.0;

func _ready():
	initial_position = position


func _physics_process(delta):
	if is_moving == false:
		process_movement_input()
	elif input_direction != Vector2.ZERO:
		move(delta);
	else:
		is_moving = false;

	#velocity = input_direction * move_speed
	
	#move_and_slide()
	#move_and_collide()


func process_movement_input():
	input_direction = Vector2(
		int( Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left") ),
		int( Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up") )
	)
	
	if input_direction != facing_direction:
		if (input_direction.x != 0) && (input_direction.y != 0) && (input_direction != Vector2.ZERO):
			input_direction = facing_direction;
	
	facing_direction = input_direction;
	
	if input_direction != Vector2.ZERO:
		initial_position = position
		is_moving = true
	

func move(delta):
	percent_moved_to_next_tile += move_speed * delta
	
	if percent_moved_to_next_tile >= 1.0:
		position = initial_position + (TILE_SIZE * input_direction);
		percent_moved_to_next_tile = 0.0
		is_moving = false
	else:
		position = initial_position + (TILE_SIZE * input_direction * percent_moved_to_next_tile)


# Written using the following tutorial videos:
#
# fornclake  --  (Youtube, Gp_98cuqXUY)
# Chris' Tutorials  --  (Youtube, Luf2Kr5s3BM)
# Arkeve  --  (Youtube, jSv5sGpnFso)
#
# Thus, I do not trust I can release this under any particular license.
# I will still release it, for my 1 (one) Twitter follower. (and also getting the project moving already)
