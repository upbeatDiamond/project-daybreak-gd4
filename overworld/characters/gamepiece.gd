extends Area2D
class_name Gamepiece

# 4th lineage player script, but with player stuff (and commented out code) scooped out...
# ... and 2nd + 3rd lineage stuff shoved into it and then trimmed down.

signal gamepiece_moving_signal
signal gamepiece_stopped_signal
signal gamepiece_entering_door_signal
signal gamepiece_entered_door_signal

# -1 = invalid / unset
# 0 = player 1
# 0-255 = reserved for players, in case of future multiplayer version
# not to be confused with UMID, which reserves 1-512 for important characters
@export var unique_id := -1

var move_speed:float
@export var walk_speed = 5.0
@export var jump_speed = 5.0
@export var run_speed = 12.0

var tile_offset = Vector2.ONE * floor(  (GlobalRuntime.DEFAULT_TILE_SIZE + 1)/2 )

const LandingDustEffect = preload("res://overworld/landing_dust_effect.tscn")

@onready var animation_tree = $AnimationTree
@onready var animation_state = animation_tree["parameters/playback"]
@onready var block_ray = $Collision/BlockingRayCast2D
@onready var event_ray = $Collision/EventRayCast2D
@onready var gfx = $GFX
@onready var shadow = $GFX/Shadow
@onready var collision = $Collision
@onready var controller = $Controller
@onready var move_tween : Tween

var is_paused = false;	# true if cannot act
var is_moving = false;	# true if walking, running, jumping, etc
var position_is_known = true;	# false if the gamepiece needs a new position calculated.
var facing_direction = Vector2(0,0);	# Used for animation state

var traversal_mode = TraversalMode.STANDING

enum TraversalMode
{
	STANDING, 	# 🧍‍♀️ 
	WALKING, 	# 🚶‍♀️ 
	RUNNING, 	# 🏃‍♂️ 
	TRUDGING, 	# Did you know you can put emojis in comments? I mean, it's text... but it renders!
	SLIDING, 	# 🧊 
	SPINNING, 	# 🔄
	SWIMMING, 	# 🏊‍♂️ 
	DIVING, 	# 🤿
	BICYCLING, 	# 🚲 
}

@export var target_map := 0
@export var target_position := Vector2(0,0)
var move_queue := []
# The movement queue should be updated to account for the ability to turn, ...
# ... and to switch traversal modes.

# Why wasn't this in the Gamepiece by Prealpha 3?
# Oh yeah, because I kept rewriting this class.
var monster : Monster


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
	
	if monster == null:
		monster = Monster.new()
	
	GlobalRuntime.pause_gameworld.connect( _on_gameworld_pause )
	GlobalRuntime.unpause_gameworld.connect( _on_gameworld_unpause )


func set_umid(new_umid:int):
	if monster == null:
		monster = Monster.new()
	monster.umid = new_umid


func _process(_delta):
	if move_queue.size() > 0 && is_moving == false:
		move(move_queue.pop_front())
	pass


func update_rays( direction ):
	
	block_ray.target_position = direction * GlobalRuntime.DEFAULT_TILE_SIZE
	block_ray.force_raycast_update()
	
	event_ray.target_position = direction * GlobalRuntime.DEFAULT_TILE_SIZE
	event_ray.force_raycast_update()
	
	pass


func move( direction ):
	
	if direction is Vector2i:
		direction = Vector2( direction.x, direction.y )
	
	update_rays(direction)
	
	if event_ray.is_colliding():
			var colliding_with = event_ray.get_collider()
			if colliding_with.is_in_group("portals"):
				colliding_with.run_event( self )
			pass
	
	if !block_ray.is_colliding():
		
		var new_position = snap_to_grid( collision.position + direction * GlobalRuntime.DEFAULT_TILE_SIZE )
		
		# Before this match is run, try looking for materials that change the...
		# ... character's speed/animation, and change the traversal mode to match.
		
		match traversal_mode:
			TraversalMode.WALKING:
				move_speed = walk_speed
				pass
			TraversalMode.RUNNING:
				move_speed = run_speed
				pass
			_:
				move_speed = walk_speed
				pass
		
		# Sometimes the gamepiece is picked up as the move() is called, so make sure we can get a tween
		if is_inside_tree():
			move_tween = create_tween()
			if move_tween != null:
				move_tween.tween_property(gfx, "position",
					new_position - tile_offset, 1/move_speed ).set_trans(Tween.TRANS_LINEAR)
				is_moving = true
				await move_tween.finished
		
		collision.position = new_position
		
		resync_position()
		is_moving = false
		traversal_mode = TraversalMode.STANDING


# Not the same as move, used for in-map teleportation.
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

func teleport_to_anchor(map:String, anchor:String):
	set_teleport(Vector2i(0,0), Vector2i(0,0), map, anchor)
	pass

func set_teleport(loci: Vector2i, direction: Vector2i, map:="", anchor_name:=""):
	is_moving = false
	
	if map.length() > 0:
		controller.handle_map_change( map )
	
	var anchor = GlobalRuntime.scene_manager.get_overworld_root().get_anchor_container().get_anchor_by_name(anchor_name)
	if anchor != null:
		loci = self.position + (anchor.global_position - self.global_position)
		direction = anchor.facing_direction
	print("anchor detail: ", anchor, " :+ name: ", anchor_name)
	
	var camera_current = (self.find_child("Camera", true) as Camera2D)
	
	loci = snap_to_grid( loci ) # This line might be redundant.
	move_to_target( loci )
	facing_direction = Vector2( direction.x, direction.y )
	
	print("teleport to gx %d, gy %d, x %d , y %d" % [global_position.x, global_position.y, loci.x, loci.y])
	
	camera_current.reset_smoothing ( )#.position_smoothing_enabled = camera_smooth


static func gamepiece_from_walker( walker:GamepieceWalker ) -> Gamepiece:
	var model_gamepiece = load("res://overworld/characters/gamepiece.tscn") as PackedScene
	var new_gamepiece = model_gamepiece.instantiate() as Gamepiece
	new_gamepiece.monster = walker.monster
	new_gamepiece.find_child("Controller").set_script( walker.controller )
	if walker.current_position_is_known:
		new_gamepiece.position = walker.current_position
	else:
		# Replace this else statement with position estimation code
		new_gamepiece.position = walker.current_position
	
	return new_gamepiece

static func walker_from_gamepiece( gamepiece:Gamepiece ) -> GamepieceWalker:
	
	var walker = GamepieceWalker.new( gamepiece.monster,
										gamepiece.controller.get_script(),
										gamepiece.get_current_map_id(),
										gamepiece.target_map,
										gamepiece.target_position )
	
	return walker
