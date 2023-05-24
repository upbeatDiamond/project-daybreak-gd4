extends Area2D

# 4th lineage player script, but with player stuff (and commented out code) scooped out...
# ... and 2nd + 3rd lineage stuff shoved into it.
# idk im not a lawyer


signal gamepiece_moving_signal
signal gamepiece_stopped_signal
signal gamepiece_entering_door_signal
signal gamepiece_entered_door_signal


#@export var grid: Grid:
#	set(value):
#		grid = value
#		update_configuration_warnings()


var move_speed: float
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
@onready var gamepiece_gfx = $GFX
@onready var shadow = $GFX/Shadow
@onready var collision = $Collision

var jumping_over_ledge: bool = false

# Should be one of: x, y, z, or n. (Updown, Leftright, Inout, and Null)
var next_taxicab_direction = 'n' 

var is_moving = false;
var is_running = false
var input_direction = Vector2(0,0);
var facing_direction = Vector2(0,0);	# Used for animation state tree
var initial_position = Vector2(0,0);	# At start of total movement
var resting_position = Vector2(0,0);	# At end of total movement, might be unused
var proportion_to_next_tile = 0.0;		# Was "percent_moved_..." but it's not a percentage?
										# ^ might be unused

var collider_size = Vector2(TILE_SIZE, TILE_SIZE)

# WARNING: order and choice of parameters may change.
func _init(collider):
	if collider != null:
		
		# Note: Need to change how collision is handled to account for potentially massive colliders.
		# Maybe round each collider up for number of cells, and if more than 1x1, flash an Area2D for collisions?
		collider_size = collider



func _ready():
	is_moving = false
	$GFX/Sprite.visible = true
	position = position.snapped(Vector2.ONE * TILE_SIZE) + (Vector2.ONE*TILE_SIZE/2)
	position += Vector2.ONE * TILE_SIZE/2
	animation_tree.active = true
	update_anim_tree()


# Phase out, move to a player controller class.
func handle_movement_input():
	input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if input_direction != facing_direction:
		if (input_direction.x != 0) && (input_direction.y != 0) && (input_direction != Vector2.ZERO):
			input_direction = facing_direction;
			pass
	
	facing_direction = input_direction;
			
	if( input_direction.y != 0 && input_direction.x != 0 ):
		if (next_taxicab_direction == 'n' || next_taxicab_direction == 'x'):
			input_direction.x = 0
			next_taxicab_direction = 'y'
		else: #if (nextTaxicabDirection == 'y'):
			input_direction.y = 0
			next_taxicab_direction = 'x'
	
	if input_direction != Vector2.ZERO:
		update_anim_tree()
		move()







func move():
	
	ray.target_position = input_direction * TILE_SIZE/2
	ray.force_raycast_update()
	if !ray.is_colliding():
		var tween = create_tween()
		tween.tween_property(self, "position",
			position + input_direction * TILE_SIZE, 1.0/move_speed).set_trans(Tween.TRANS_LINEAR)
		is_moving = true
		await tween.finished
		is_moving = false





func _physics_process(delta):
	if GlobalRuntime.gameworld_input_stopped:
		return
	
	is_running = Input.is_action_pressed("ui_fast")
	if is_running:
		move_speed = run_speed
	else:
		move_speed = walk_speed
	
	if is_moving == false:
		handle_movement_input()



func entered_door():
	emit_signal("gamepiece_entered_door_signal")




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
	facing_direction = direction
	animation_tree.set("parameters/Idle/blend_position", direction)
	animation_tree.set("parameters/Walk/blend_position", direction)
	
	animation_state.travel("Idle")
	
	global_position.x = loci.x + 20
	global_position.y = loci.y + 20
	print("gx %d, gy %d, x %d , y %d" % [global_position.x, global_position.y, loci.x, loci.y])
	visible = true
	
	GlobalRuntime.gameworld_input_stopped = false
	$AnimationPlayer.play("Appear")



#
#
#	## Emitted when a gamepiece is about to finish travlling to its destination cell. The remaining
#	## distance that the gamepiece could travel is based on how far the gamepiece has travelled this
#	## frame. [br][br]
#	## The signal is emitted prior to wrapping up the path and traveller, allowing other objects to
#	## extend the move path, if necessary.
#	signal arriving(remaining_distance: float)
#
#	## Emitted when the gamepiece has finished travelling to its destination cell.
#	signal arrived
#	signal blocks_movement_changed
#	signal cell_changed(old_cell: Vector2i)
#	signal direction_changed(new_direction: Vector2)
#
#	## Emitted when the gamepiece begins to travel towards a destination cell.
#	signal travel_begun
#
#	## The gamepiece's position is snapped to whichever cell it currently occupies. [br][br]
#	## The gamepiece will move by steps, being placed at whichever cell it currently occupies. This is
#	## useful for snapping it's collision shape to the grid, so that there is never ambiguity to which
#	## space/cell is occupied in the physics engine. [br][br]
#	## It is not desirable, however, for the graphical representation of the gamepiece (or the camera!)
#	## to jump around the gameboard with the gamepiece. Rather, a follower will travel a movement path
#	## to give the appearance of smooth movement. Other objects (such as sprites and animation) will
#	## derive their position from this follower and, consequently, appear to move smoothly.
#	var cell := Vector2i.ZERO: set = set_cell
#
#	func set_cell(value: Vector2i) -> void:
#		if Engine.is_editor_hint():
#			return
#
#		var old_cell: = cell
#		cell = value
#
#		if not is_inside_tree():
#			await ready
#
#		print("Set cell to ", cell)
#
#		var old_position: = position
#		position = grid.cell_to_pixel(cell)
#		_follower.position = old_position
#
#		cell_changed.emit(old_cell)
#		GlobalFieldEvents.gamepiece_cell_changed.emit(self, old_cell)
#
#	# The following objects allow the gamepiece to appear to move smoothly around the gameboard.
#	# Please note that the path is decoupled from the gamepiece's position (scale is set to match
#	# the gamepiece in _ready(), however) in order to simplify path management. All path coordinates may 
#	# be provided in game-world coordinates and will remain relative to the origin even as the 
#	# gamepiece's position changes.
#	@onready var _path: = $Decoupler/Path2D as Path2D
#	@onready var _follower: = $Decoupler/Path2D/PathFollow2D as PathFollow2D
#
#	## Calling travel_to_cell on a moving gamepiece will update it's position to that indicated by the
#	## cell coordinates and add the cell to the movement path.
#	func travel_to_cell(destination_cell: Vector2i) -> void:
#		# Note that updating the gamepiece's cell will snap it to its new grid position. This will
#		# be accounted for below when calculating the waypoint's pixel coordinates.
#		var old_position: = position
#		cell = destination_cell
#
#		# If the gamepiece is not yet moving, we'll setup a new path.
#		if not _path.curve:
#			_path.curve = Curve2D.new()
#
#			# The path needs at least two points for the follower to work correctly, so a new path
#			# will travel from the gamepiece's old position.
#			_path.curve.add_point(old_position)
#			_follower.progress = 0
#
#			set_physics_process(true)
#
#		# The gamepiece serves as the waypoint's frame of reference.
#		_path.curve.add_point(grid.cell_to_pixel(destination_cell))
#
#		travel_begun.emit()
#
#
#	func _get_configuration_warnings() -> PackedStringArray:
#		var warnings: PackedStringArray = []
#		if not grid:
#			warnings.append("Gamepiece requires a Grid object to function!")
#
#		return warnings
#
#
#
#	# find_parent ( String pattern )
