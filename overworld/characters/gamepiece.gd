extends Area2D
class_name Gamepiece

# 4th lineage player script, but with player stuff (and commented out code) scooped out...
# ... and 2nd + 3rd lineage stuff shoved into it and then trimmed down.

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

# -1 = invalid / unset
# 0 = player 1
# 0-255 = reserved for players, in case of future multiplayer version
@export var unique_id := -1

var move_speed:float
@export var walk_speed = 5.0
@export var jump_speed = 5.0
@export var run_speed = 12.0

#const TILE_SIZE = 16
var tile_offset = Vector2.ONE * (  (GlobalRuntime.DEFAULT_TILE_SIZE + 1)/2 as int )

const LandingDustEffect = preload("res://overworld/landing_dust_effect.tscn")

@onready var animation_tree = $AnimationTree
@onready var animation_state = animation_tree["parameters/playback"]
@onready var block_ray = $Collision/BlockingRayCast2D
@onready var ledge_ray = $Collision/LedgeRayCast2D
@onready var event_ray = $Collision/EventRayCast2D
@onready var gfx = $GFX
@onready var shadow = $GFX/Shadow
@onready var collision = $Collision
@onready var controller = $Controller
@onready var move_tween : Tween

var jumping_over_ledge: bool = false

var is_paused = false;	# true if cannot act
var is_moving = false;	# true if walking, running, jumping, etc
var is_running = false;	# set to true to use run speed instead of walk speed
var facing_direction = Vector2(0,0);	# Used for animation state tree

@export var target_position := Vector2(0,0)
var move_queue := []

#var agent_id : int

#func _init(): #agent : RID
#	agent_id = self.get_instance_id() #agent
#	pass
# Why use RIDs when you can use instance ids?
# There are probably good reasons, but I dunno yet.

func _on_gameworld_pause():
	if move_tween != null:
		move_tween.pause()
	is_paused = true
	#print("Stop! GlobalRuntime.")
	pass

func _on_gameworld_unpause():
	if move_tween != null:
		move_tween.play()
	is_paused = false
	#print("I can run? I CAN FIGHT!")
	pass

func snap_to_grid( pos ) -> Vector2:
	return Vector2(pos.x - tile_offset.x, pos.y - tile_offset.y).snapped(Vector2.ONE * GlobalRuntime.DEFAULT_TILE_SIZE) + tile_offset

func _ready():
	is_moving = false
	$GFX/Sprite.visible = true
	snap_to_grid( position )
	animation_tree.active = true
	update_anim_tree()
	
	GlobalRuntime.pause_gameworld.connect( _on_gameworld_pause )
	GlobalRuntime.unpause_gameworld.connect( _on_gameworld_unpause )

func _process(delta):
	#print("gp = %s" % self.get_class())
	if move_queue.size() > 0 && is_moving == false:
		move(move_queue.pop_front())
	pass

#func _physics_process(delta):
	#if GlobalRuntime.gameworld_input_stopped:
	#	return
	#elif is_moving == false:
	#	handle_movement_input()
#	pass



func update_rays( direction ):
	
	block_ray.target_position = direction * GlobalRuntime.DEFAULT_TILE_SIZE
	block_ray.force_raycast_update()
	
	event_ray.target_position = direction * GlobalRuntime.DEFAULT_TILE_SIZE
	event_ray.force_raycast_update()
	
	#if event_ray.is_colliding():
	#	print("Hewwo doow!")
	
	pass


func move( direction ):
	if direction is Vector2i:
		direction = Vector2( direction.x, direction.y )
	
	update_rays(direction)
	
	if event_ray.is_colliding():
			var colliding_with = event_ray.get_collider()
			#print( colliding_with )
			if colliding_with.is_in_group("portals"):
				colliding_with.run_event( self )
			pass
	
	if !block_ray.is_colliding():
		
		var old_position = collision.position # 
		var new_position = snap_to_grid( collision.position + direction * GlobalRuntime.DEFAULT_TILE_SIZE )
		
		collision.position = new_position
		
		# If there's an event here OR it's a valid space, move the collider forward.
		# If it's not a valid space, run the events and then move the collider back.
		#if block_ray_colliding
		
		
		move_tween = create_tween()
		move_tween.tween_property(gfx, "position",
			new_position - tile_offset, 1/move_speed ).set_trans(Tween.TRANS_LINEAR)
		is_moving = true
		await move_tween.finished
		resync_position()
		is_moving = false



func move_to_target( target:Vector2i ):
	var new_position = snap_to_grid( target )
	
	self.position = new_position - tile_offset
	resync_position()



func entered_door():
	emit_signal("gamepiece_entered_door_signal")



func queue_move( direction:Vector2 ):
	move_queue.append( direction )
	pass



func resync_position():
	var collision_gp = collision.global_position
	var gfx_gp = gfx.global_position
	
	self.global_position = collision_gp - (Vector2.ONE * tile_offset)
	collision.global_position = collision_gp
	gfx.global_position = gfx_gp
	pass


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
	#animation_tree.set("parameters/Idle/blend_position", direction)
	#animation_tree.set("parameters/Walk/blend_position", direction)
	
	#animation_state.travel("Idle")
	
	if map.length() > 0:
		controller.handle_map_change( map )
	
	loci = snap_to_grid( loci )
	move_to_target( loci )
	
	print("teleport to gx %d, gy %d, x %d , y %d" % [global_position.x, global_position.y, loci.x, loci.y])
	#visible = true
	
	#GlobalRuntime.gameworld_input_stopped = false
	#$AnimationPlayer.play("Appear")
