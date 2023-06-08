extends CharacterBody2D

# As the name implies, this is the 5th player attempt
# It is abandoned. What a shame that the odd numbered attempts are failures.


var move_speed:float
@export var walk_speed = 5.0
@export var jump_speed = 5.0
@export var run_speed = 12.0
const TILE_SIZE = 16


var jumping_over_ledge: bool = false

# Should be one of: x, y, z, or n. (Updown, Leftright, Inout, and Null)
var next_taxicab_direction = 'n' 

#var is_moving = false;
var is_running = false
var input_direction = Vector2(0,0);
var facing_direction = Vector2(0,0);	# Used for animation state tree
var initial_position = Vector2(0,0);	# At start of total movement
var resting_position = Vector2(0,0);	# At end of total movement, might be unused
var proportion_to_next_tile = 0.0;		# Was "percent_moved_..." but it's not a percentage?
										# ^ might be unused




var direction: Vector2 = Vector2.ZERO
var pixels_per_second := 220.0 : 
	set(value) : 
		pixels_per_second = value
		_step_size = (1 / pixels_per_second)

var _step_size: float
#func _pixels_per_second_changed(value: float) -> void:
	

var _step: float = 0 # Accumulates delta, aka fractions of seconds, to time movement
var _pixels_moved: int = 0  # Count movement in distinct integer steps

#func show_coordinates() -> void:
#	$Label.text = "x: %d (%dpx)\ny: %d (%dpx)" % [
#		self.position.x / TILE_SIZE, self.position.x,
#		self.position.y / TILE_SIZE, self.position.y
#	]

func is_moving() -> bool:
	return self.direction.x != 0 or self.direction.y != 0

func _ready() -> void:
	_step_size = (1 / pixels_per_second)
	pass
	#self.pixels_per_second = 1 * TILE_SIZE

#func _process(delta: float) -> void:
#	show_coordinates()

func _physics_process(delta: float) -> void:
	if not is_moving(): return
	# delta is measured in fractions of seconds, so for a speed of
	# 4 pixels_per_second, we need to accumulate deltas until we
	# reach 1 / 4 = 0.25
	_step += delta
	if _step < _step_size: return

	# Move a pixel
	_step -= _step_size
	_pixels_moved += 1
	move_and_collide(direction)

	# Complete movement
	if _pixels_moved >= TILE_SIZE:
		direction = Vector2.ZERO
		_pixels_moved = 0
		_step = 0

func _input(event: InputEvent) -> void:
	if is_moving(): return
	if Input.is_action_pressed("ui_right"):
		direction = Vector2(1, 0)
	elif Input.is_action_pressed("ui_left"):
		direction = Vector2(-1, 0)
	elif Input.is_action_pressed("ui_down"):
		direction = Vector2(0, 1)
	elif Input.is_action_pressed("ui_up"):
		direction = Vector2(0, -1)
