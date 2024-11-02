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
@export var unique_id := -1	# may be removed unless useful for screenplays
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
@export var run_speed = 8.0

const LandingDustEffect = preload("res://overworld/landing_dust_effect.tscn")

@onready var animation_tree = $AnimationTree
@onready var animation_state #= animation_tree["parameters/playback"]
@onready var block_ray : RayCast2D = $Collision/BlockingRayCast2D
@onready var event_ray : RayCast2D = $Collision/EventRayCast2D
@onready var gfx = $GFX
@onready var shadow = $GFX/Shadow
@onready var collision : CollisionShape2D = $Collision
@onready var controller = $Controller
@onready var move_tween : Tween
@onready var my_camera = (self.find_child("Camera", true) as Camera2D)

var is_paused = false;	# true if cannot act; this shouldn't be set by Gamepiece OR its controller
var is_moving = false;	# true if currently tweening a traversal (walking, running, jumping, etc)
var was_moving = false;	# true if animation for an 'is_moving' action would still be playing
var position_is_known = true;	# false if the gamepiece needs a new position calculated.
var position_stabilized = false;	#current_position == global_position; or, "has been placed yet"
var facing_direction = Vector2(0,-1):	# Used for animation state
	set(value):
		facing_direction = value

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

@export var current_map := -1	# depricated, please ask the local map for its ID
@export var current_position := Vector2i(0,0):
	set( pos ): 
		shift_to_target(pos)
		current_position = pos#self.global_position 
	get:
		if position_stabilized:
			return self.global_position
		return current_position 

@export var target_map := 0
@export var target_position := Vector2(0,0)
var move_queue :Array[Movement] = []
# ^ The movement queue should be updated to account for the ability to turn, ...
# ... and to switch traversal modes.

@export var monster : Monster
# The 'soul' of the gamepiece.
# The gamepiece is but a vehicle to the spirit (that which stores name, stats, species, etc)


signal gamepiece_moved( direction:Vector2, global_endpoint:Vector2, mode:TraversalMode )
signal gamepiece_moving( direction:Vector2, global_endpoint:Vector2, mode:TraversalMode )


func _init():
	GlobalRuntime.save_data.connect( save_gamepiece )
	monster = Monster.new()
	monster.umid = umid


func _ready():
	add_to_group("gamepiece")
	
	# "animation_tree" serves as a canary for overall loading issues.
	if animation_tree == null:
		get_parent().add_child( GlobalGamepieceTransfer.reform_gamepiece_treelet( self ) )
		get_parent().remove_child( self )
		return
	
	animation_state = animation_tree["parameters/playback"]
	my_camera = (self.find_child("Camera", true) as Camera2D)
	
	is_moving = false
	$GFX/SpriteBase.visible = true
	$GFX/SpriteAccent.visible = true
	$GFX/SpriteClothes.visible = true
	GlobalRuntime.snap_to_grid( position )
	animation_tree.active = true
	update_anim_tree()
	
	if monster == null:
		monster = Monster.new()
	
	GlobalRuntime.pause_gameworld.connect( _on_gameworld_pause )
	GlobalRuntime.unpause_gameworld.connect( _on_gameworld_unpause )
	print("GP: I think I'm at ", current_position, "")


func _process(_delta):
	if not is_paused:
		if move_queue.size() > 0 && is_moving == false:
			move( (move_queue.pop_front() as Movement) )
		elif is_moving == true:
			was_moving = true
		elif was_moving == true: # implied: is_moving is false
			update_anim_tree()
			was_moving = false
	


func _on_gameworld_pause():
	if move_tween != null:
		move_tween.pause()
	is_paused = true
	#print("Stop! GlobalRuntime.")


func _on_gameworld_unpause():
	if move_tween != null && move_tween.is_valid():
		move_tween.play()
	is_paused = false
	#print("I can run? I CAN FIGHT!")


func set_umid(new_umid:int):
	if monster == null:
		monster = Monster.new()
	monster.umid = new_umid


func update_rays( direction : Vector2 ):
	block_ray.target_position = direction * GlobalRuntime.DEFAULT_TILE_SIZE
	block_ray.force_raycast_update()
	
	event_ray.target_position = direction * GlobalRuntime.DEFAULT_TILE_SIZE
	event_ray.force_raycast_update()


func move( direction ):
	
	if direction is Movement:
		traversal_mode = direction.method
		direction = direction.to_cell_vector2f()
	elif direction is Vector2i:
		direction = Vector2( direction.x, direction.y )
	
	if direction == Vector2.ZERO:
		return
	facing_direction = direction
	
	update_rays(direction)
	
	if event_ray.is_colliding():
		var colliding_with = event_ray.get_collider()
		if colliding_with.is_in_group("event_exterior") and colliding_with.has_method("run_event"):
			colliding_with.run_event( self )
	
	if !block_ray.is_colliding():
		
		var colliding_within
		if event_ray.is_colliding():
			colliding_within = event_ray.get_collider()
		
		var new_position = GlobalRuntime.snap_to_grid(collision.position + \
			(direction * GlobalRuntime.DEFAULT_TILE_SIZE) )
		
		# Before this match is run, try looking for materials that change the...
		# ... character's speed/animation, and change the traversal mode to match.
		
		match traversal_mode:
			TraversalMode.WALKING:
				move_speed = walk_speed
			TraversalMode.RUNNING:
				move_speed = run_speed
			_:
				move_speed = walk_speed
		update_anim_tree()
		
		
		collision.position = new_position
		
		# Sometimes the gamepiece is picked up as move() is called, so make sure we can get a tween
		if is_inside_tree():
			move_tween = create_tween()
			if move_tween != null:
				move_tween.tween_property(gfx, "position",
					new_position - GlobalRuntime.DEFAULT_TILE_OFFSET, 
					1/move_speed ).set_trans(Tween.TRANS_LINEAR)
				is_moving = true
				await move_tween.finished
		
		resync_position()
		
		if colliding_within != null and \
		colliding_within.is_in_group("event_interior") and \
		colliding_within.has_method("run_event"):
			colliding_within.run_event( self )
	is_moving = false
	traversal_mode = TraversalMode.STANDING
	
	for overlap in get_overlapping_areas():
		if overlap.is_in_group("event_interior") and overlap.has_method("run_event"):
			overlap.run_event(self)

# Not the same as move, used for in-map teleportation.
func shift_to_target( target:Vector2i ):
	var new_position = GlobalRuntime.snap_to_grid_corner_f( target )
	self.global_position = new_position
	resync_position()
	
	
	#if collision != null:
	#	collision.global_position = GlobalRuntime.snap_to_grid_center_f( target )
	#resync_position()


func entered_door():
	emit_signal("gamepiece_entered_door_signal")


func queue_movement( movement:Movement ):
	move_queue.append( movement )


func resync_position():
	if collision == null:
		return
	print("gp ", umid, "/", unique_id, " global position ~ ", current_position)
	
	var collision_gp = collision.global_position
	var gfx_gp = collision.global_position - (GlobalRuntime.DEFAULT_TILE_OFFSET)
	#if gfx != null:
	#	gfx_gp = gfx.global_position
	
	self.global_position = Vector2(collision_gp) - (Vector2.ONE * GlobalRuntime.DEFAULT_TILE_OFFSET)
	collision.global_position = Vector2(collision_gp)
	if gfx != null:
		gfx.global_position = Vector2(gfx_gp)


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


func set_teleport(loci: Vector2i, direction: Vector2i, map:="", anchor_name:="", silent:=false):
	is_moving = false
	
	var pause_prior: bool 
	pause_prior = await controller.handle_map_change( map, silent )
	
	var map_root = GlobalRuntime.scene_manager.get_overworld_root()
	var anchor_container
	var anchor
	
	if map_root != null:
		anchor_container = map_root.get_anchor_container()
	if anchor_container != null:
		anchor = anchor_container.get_anchor_by_name(anchor_name)
	if anchor != null:
		loci = anchor.global_position 
		direction = anchor.facing_direction
	print("anchor detail: ", anchor, " :+ name: ", anchor_name)
	
	shift_to_target( loci )
	facing_direction = Vector2( direction.x, direction.y )
	
	print("teleport: gx %d, gy %d, x %d, y %d"%[global_position.x,global_position.y,loci.x,loci.y])
	
	my_camera.reset_smoothing()
	
	controller.finalize_map_change( pause_prior, silent )


func kill_imposters():
	var other_pieces = get_tree().get_nodes_in_group("gamepiece")
	for piece in other_pieces:
		if piece == self:
			pass
		elif piece is Gamepiece and piece.monster.equals(monster):
			if !piece.is_inside_tree():
				piece.umid = -1
				piece.queue_free()
			elif !is_inside_tree():
				umid = -1
				queue_free()
			elif piece.unique_id == unique_id:
				piece.unique_id *= 2
		pass
	return true


# ONLY USE TO SAVE THE GAMEPIECE LIVE, like ON THE FIELD.
# This function as a non-descriptive name because this is an EARLY BUILD
# Unless... it fixed itself and can be used anywhere?
func save_gamepiece():
	if is_inside_tree():
		kill_imposters()
		current_position = global_position
		current_map = GlobalRuntime.scene_manager.get_overworld_root().map_index
	else:
		return
	print("save gp ", umid, "/", unique_id, " global position ~ ", current_position)
	GlobalDatabase.save_gamepiece(self)
	pass


func transfer_data_from_gp(gamepiece:Gamepiece):
	var bool_pidgeonhole = false
	unique_id = gamepiece.unique_id
	umid = gamepiece.umid
	monster = gamepiece.monster
	
	bool_pidgeonhole = gamepiece.position_stabilized
	gamepiece.position_stabilized = true
	current_position = gamepiece.current_position
	gamepiece.position_stabilized = bool_pidgeonhole
	
	facing_direction = gamepiece.facing_direction
	if gamepiece.controller != null:
		controller.set_script( gamepiece.controller.get_script() )
	pass


static func gamepiece_from_walker( walker:GamepieceWalker ) -> Gamepiece:
	var model_gamepiece = load("res://overworld/characters/gamepiece.tscn") as PackedScene
	var new_gamepiece = model_gamepiece.instantiate() as Gamepiece
	new_gamepiece.monster = walker.monster
	new_gamepiece.find_child("Controller").set_script( walker.controller )
	if walker.current_position_is_known:
		new_gamepiece.position = walker.current_position
	else:
		#TODO: Replace this else statement with position estimation code
		new_gamepiece.position = walker.current_position
	
	return new_gamepiece


static func walker_from_gamepiece( gamepiece:Gamepiece ) -> GamepieceWalker:
	
	var walker = GamepieceWalker.new( gamepiece.monster, gamepiece.controller.get_script(), \
		gamepiece.get_current_map_id(), gamepiece.target_map, gamepiece.target_position )
	
	return walker
