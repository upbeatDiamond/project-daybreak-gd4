extends CharacterBody2D

@export var move_speed : float = 8.0
const TILE_SIZE = 16

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree["parameters/playback"]

var is_moving = false;
var input_direction = Vector2(0,0);
var facing_direction = Vector2(0,0);
var initial_position = Vector2(0,0);
var percent_moved_to_next_tile = 0.0;

func _ready():
	initial_position = position
	animation_tree.active = true
	update_anim_tree()


func _physics_process(delta):
	if is_moving == false:
		process_movement_input()
	elif input_direction != Vector2.ZERO:
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
	
	if input_direction != Vector2.ZERO:
		initial_position = position
		is_moving = true
		update_anim_tree()


func move(delta):
	percent_moved_to_next_tile += move_speed * delta
	
	if percent_moved_to_next_tile >= 1.0:
		position = initial_position + (TILE_SIZE * input_direction);
		percent_moved_to_next_tile = 0.0
		is_moving = false
	else:
		position = initial_position + (TILE_SIZE * input_direction * percent_moved_to_next_tile)


func update_anim_tree():
	animation_tree.set("parameters/Idle/blend_position", facing_direction)
	animation_tree.set("parameters/Walk/blend_position", facing_direction)
	
	if is_moving == true:
		state_machine.travel("Walk")
	else:
		state_machine.travel("Idle")
