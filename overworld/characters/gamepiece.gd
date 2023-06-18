extends Area2D
class_name Gamepiece

# 4th lineage player script, but with player stuff (and commented out code) scooped out...
# ... and 2nd + 3rd lineage stuff shoved into it.

# As for unique features, consider this:
# Each tile contains navigation layer value(s)
# For each navigation layer, there could be an AStar Grid
# But how would transition tiles, or transitions between tile flavors work?
# Easy, have the flavor transition cost extra.
# Have the Navigation path be snapped to the nearest valid tile, and AStar to it.
# Each Gamepiece needs a Navigation agent (not Agent class, but agent RID) and to be a descendent of a Board
# Each Board inherits a TileMap which in turn uses a Navigation Map


signal gamepiece_moving_signal
signal gamepiece_stopped_signal
signal gamepiece_entering_door_signal
signal gamepiece_entered_door_signal

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
@onready var collision = $Collision as CollisionObject2D

var jumping_over_ledge: bool = false

var is_moving = false;
var is_running = false
var facing_direction = Vector2(0,0);	# Used for animation state tree


var agent_id : RID

func _init( agent : RID ):
	agent_id = agent
	pass



func snap_to_grid( pos ) -> Vector2:
	var tile_offset = (Vector2.ONE*TILE_SIZE/2)
	return (pos - tile_offset).snapped(Vector2.ONE * TILE_SIZE) + tile_offset
	pass

func _ready():
	is_moving = false
	$GFX/Sprite.visible = true
	snap_to_grid( position )
	animation_tree.active = true
	update_anim_tree()

func _process(delta):
	print("gp = %s" % self.get_class())

func _physics_process(delta):
	#if GlobalRuntime.gameworld_input_stopped:
	#	return
	#elif is_moving == false:
	#	handle_movement_input()
	pass



func move( direction ):
	ray.target_position = direction * TILE_SIZE
	ray.force_raycast_update()
	if !ray.is_colliding():
		
		var new_position = snap_to_grid( collision.position + direction * TILE_SIZE )
		
		collision.position = new_position
		
		var tween = create_tween()
		tween.tween_property(player_gfx, "position",
			new_position - tile_offset, 1.0/move_speed).set_trans(Tween.TRANS_LINEAR)
		is_moving = true
		await tween.finished
		is_moving = false



func move_to_target( target:Vector2i ):
	move( target - collision.position )



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



func set_teleport(loci: Vector2i, direction: Vector2i, map:=""):
	is_moving = false
	animation_tree.set("parameters/Idle/blend_position", direction)
	animation_tree.set("parameters/Walk/blend_position", direction)
	
	animation_state.travel("Idle")
	
	loci = snap_to_grid( loci )
	move_to_target( loci )
	
	print("teleport to gx %d, gy %d, x %d , y %d" % [global_position.x, global_position.y, loci.x, loci.y])
	visible = true
	
	GlobalRuntime.gameworld_input_stopped = false
	$AnimationPlayer.play("Appear")
