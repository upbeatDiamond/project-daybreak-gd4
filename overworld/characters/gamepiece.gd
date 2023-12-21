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
@export var umid := -1:
	set(_umid):
		umid = _umid
		if monster != null:
			monster.umid = _umid
	get:
		if monster != null:
			return monster.umid
		return umid

var move_speed:float
@export var walk_speed = 5.0
@export var jump_speed = 5.0
@export var run_speed = 12.0

#var tile_offset = Vector2.ONE * floor(  (GlobalRuntime.DEFAULT_TILE_SIZE + 1)/2 )

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
@onready var my_camera = (self.find_child("Camera", true) as Camera2D)

var is_paused = false;	# true if cannot act
var is_moving = false;	# true if walking, running, jumping, etc
var was_moving = false;	# true if animation for an 'is_moving' action would still be playing
var position_is_known = true;	# false if the gamepiece needs a new position calculated.
var facing_direction = Vector2(0,0);	# Used for animation state

var traversal_mode = TraversalMode.STANDING

enum TraversalMode
{
	STANDING, 	# 🧍‍♀️ 
	WALKING, 	# 🚶‍♀️ 
	RUNNING, 	# 🏃‍♂️ 
	TRUDGING, 	# Did you know you can put emojis in comments? Sure, it's text, but woah it renders!
	SLIDING, 	# 🧊 
	SPINNING, 	# 🔄
	SWIMMING, 	# 🏊‍♂️ 
	DIVING, 	# 🤿
	BICYCLING, 	# 🚲 
}

@export var current_map := -1
@export var current_position := Vector2i(0,0):
	set( pos ): 
		move_to_target(pos)
		current_position = self.global_position 
	get:
		return self.global_position 

@export var target_map := 0
@export var target_position := Vector2(0,0)
var move_queue :Array[Movement] = []
# ^ The movement queue should be updated to account for the ability to turn, ...
# ... and to switch traversal modes.

var monster : Monster
# The 'soul' of the gamepiece.
# The gamepiece is but a vehicle to the spirit (that which stores name, stats, species, etc)


func _ready():
	is_moving = false
	$GFX/Sprite.visible = true
	GlobalRuntime.snap_to_grid( position )
	animation_tree.active = true
	#update_anim_tree()
	
	if monster == null:
		monster = Monster.new()
	
	GlobalRuntime.pause_gameworld.connect( _on_gameworld_pause )
	GlobalRuntime.unpause_gameworld.connect( _on_gameworld_unpause )


func _process(_delta):
	if move_queue.size() > 0 && is_moving == false:
		move( (move_queue.pop_front() as Movement) )
	elif is_moving == true:
		was_moving = true
	elif was_moving == true: # implied: is_moving is false
		#traversal_mode = TraversalMode.STANDING
		update_anim_tree()
	pass


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

# This should be the longest line of code in the entire codebase.
#func snap_to_grid( pos ) -> Vector2:
#	return Vector2(pos.x - tile_offset.x, pos.y - tile_offset.y).snapped(Vector2.ONE * GlobalRuntime.DEFAULT_TILE_SIZE) + tile_offset


func set_umid(new_umid:int):
	if monster == null:
		monster = Monster.new()
	monster.umid = new_umid


func update_rays( direction ):
	
	block_ray.target_position = direction * GlobalRuntime.DEFAULT_TILE_SIZE
	block_ray.force_raycast_update()
	
	event_ray.target_position = direction * GlobalRuntime.DEFAULT_TILE_SIZE
	event_ray.force_raycast_update()
	
	pass


func move( direction ):
	
	if direction is Movement:
		traversal_mode = direction.method
		direction = direction.to_cell_vector2f()
	elif direction is Vector2i:
		direction = Vector2( direction.x, direction.y )
	
	facing_direction = direction
	
	update_rays(direction)
	
	if event_ray.is_colliding():
		var colliding_with = event_ray.get_collider()
		if colliding_with.is_in_group("event_exterior") and colliding_with.has_method("run_event"):
			colliding_with.run_event( self )
		pass
	
	if !block_ray.is_colliding():
		
		var new_position = GlobalRuntime.snap_to_grid(collision.position+direction*GlobalRuntime.DEFAULT_TILE_SIZE)
		
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
		update_anim_tree()
		
		# Sometimes the gamepiece is picked up as the move() is called, so make sure we can get a tween
		if is_inside_tree():
			move_tween = create_tween()
			if move_tween != null:
				move_tween.tween_property(gfx, "position",
					new_position - GlobalRuntime.DEFAULT_TILE_OFFSET, 1/move_speed ).set_trans(Tween.TRANS_LINEAR)
				is_moving = true
				await move_tween.finished
		
		collision.position = new_position
		
		resync_position()
		is_moving = false
		traversal_mode = TraversalMode.STANDING
	
	for overlap in get_overlapping_areas():
		if overlap.is_in_group("event_interior") and overlap.has_method("run_event"):
			overlap.run_event(self)

# Not the same as move, used for in-map teleportation.
func move_to_target( target:Vector2i ):
	var new_position = GlobalRuntime.snap_to_grid( target )
	
	self.position = new_position - GlobalRuntime.DEFAULT_TILE_OFFSET
	resync_position()


func entered_door():
	emit_signal("gamepiece_entered_door_signal")


func queue_movement( movement:Movement ):
	move_queue.append( movement )
	pass


func resync_position():
	var collision_gp = collision.global_position
	var gfx_gp = gfx.global_position
	
	self.global_position = collision_gp - (Vector2.ONE * GlobalRuntime.DEFAULT_TILE_OFFSET)
	collision.global_position = collision_gp
	gfx.global_position = gfx_gp
	pass


func update_anim_tree():
	if facing_direction.x != 0 || facing_direction.y != 0:
		animation_tree.set("parameters/Idle/blend_position", facing_direction)
		animation_tree.set("parameters/Walk/blend_position", facing_direction)
		animation_tree.set("parameters/Run/blend_position", facing_direction)
	
	match traversal_mode:
		TraversalMode.WALKING:
			animation_state.travel("Walk", false)
		TraversalMode.RUNNING:
			animation_state.travel("Run", false)
		_:
			animation_state.travel("Idle", false)
			pass


func set_spawn(loci: Vector2, direction: Vector2):
	set_teleport(loci, direction)


func teleport_to_anchor(map:String, anchor:String):
	set_teleport(Vector2i(0,0), Vector2i(0,0), map, anchor)
	pass


func set_teleport(loci: Vector2i, direction: Vector2i, map:="", anchor_name:=""):
	is_moving = false
	
	if map.length() > 0:
		controller.handle_map_change( map )
	
	var map_root = GlobalRuntime.scene_manager.get_overworld_root()
	var anchor_container
	var anchor
	
	if map_root != null:
		anchor_container = map_root.get_anchor_container()
	if anchor_container != null:
		anchor = anchor_container.get_anchor_by_name(anchor_name)
	if anchor != null:
		loci = self.position + (anchor.global_position - self.global_position)
		direction = anchor.facing_direction
	print("anchor detail: ", anchor, " :+ name: ", anchor_name)
	
	loci = GlobalRuntime.snap_to_grid( loci ) # This line might be redundant.
	move_to_target( loci )
	facing_direction = Vector2( direction.x, direction.y )
	
	print("teleport: gx %d, gy %d, x %d, y %d"%[global_position.x,global_position.y,loci.x,loci.y])
	
	my_camera.reset_smoothing()


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
	
	var walker = GamepieceWalker.new( gamepiece.monster, gamepiece.controller.get_script(), \
		gamepiece.get_current_map_id(), gamepiece.target_map, gamepiece.target_position )
	
	return walker
