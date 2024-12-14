extends StaticBody2D
class_name Gamepiece

# 4th lineage player script, but with player stuff (and commented out code) scooped out...
# ... and 2nd + 3rd lineage stuff shoved into it and then trimmed down.

signal gamepiece_moving_signal
signal gamepiece_stopped_signal
signal gamepiece_entering_door_signal
signal gamepiece_entered_door_signal


signal gamepiece_moved( direction:Vector2, global_endpoint:Vector2, mode:TraversalMode )
signal gamepiece_moving( direction:Vector2, global_endpoint:Vector2, mode:TraversalMode )


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
var walk_speed = 5.0
var jump_speed = 5.0
var run_speed = 8.0
@export var treat_as_player := false
@export var is_local_player := false
@export var tag = ""

const LandingDustEffect = preload("res://overworld/landing_dust_effect.tscn")

@onready var animation_tree = $AnimationTree
@onready var animation_state #= animation_tree["parameters/playback"]
#@onready var block_ray : RayCast2D = $Collision/BlockingRayCast2D
@onready var event_ray : RayCast2D = $Collision/EventRayCast2D
@onready var gfx = $GFX
@onready var shadow = $GFX/Shadow
@onready var collision : CollisionShape2D = $Collision
@onready var controller = $Controller
@onready var move_tween : Tween
@onready var my_camera : PhantomCamera2D = null

var is_paused = false;	# true if cannot act; this shouldn't be set by Gamepiece OR its controller
var is_moving = false;	# true if currently tweening a traversal (walking, running, jumping, etc)
var was_moving = false;	# true if animation for an 'is_moving' action would still be playing
var position_is_known = true;	# false if the gamepiece needs a new position calculated.
var position_stabilized = false;	#current_position == global_position; or, "has been placed yet"
@export var facing_direction = Vector2(0,-1):	# Used for animation state
	set(value):
		facing_direction = value

var traversal_mode = TraversalMode.STANDING

enum TraversalMode
{
	STANDING, 	# 🧍‍♀️ 
	WALKING, 	# 🚶‍♀️ 
	RUNNING, 	# 🏃‍♂️ 
	TRUDGING, 	# Did you know comments can have emojis? It may be text, but woah it renders!
	SLIDING, 	# 🧊 
	SPINNING, 	# 🔄
	SWIMMING, 	# 🏊‍♂️ 
	DIVING, 	# 🤿
	BICYCLING, 	# 🚲 
}

var current_map := -1	# depricated, overwritten by code, do not trust
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


func _init():
	GlobalRuntime.save_data.connect( save_gamepiece )
	monster = Monster.new()
	monster.umid = umid


func _ready():
	add_to_group("gamepiece")
	controller.set_script(load("res://overworld/characters/gamepiece_controller.gd"))
	
	# "animation_tree" serves as a canary for overall loading issues.
	if animation_tree == null:
		get_parent().add_child( GlobalGamepieceTransfer.reform_gamepiece_treelet( self ) )
		get_parent().remove_child( self )
		return
	
	if facing_direction == null:
		facing_direction = Vector2(0,1)
	
	animation_state = animation_tree["parameters/playback"]
	my_camera = (self.find_child("PhantomCamera", true) as PhantomCamera2D)
	my_camera.tween_resource = PhantomCameraTween.new()
	my_camera.tween_resource.duration = 0
	
	if GlobalDatabase.is_gamepiece_player(self):
		my_camera.priority = 1
		my_camera.follow_mode = PhantomCamera2D.FollowMode.GLUED
		my_camera.follow_target = gfx
	
	is_moving = false
	$GFX/SpriteBase.visible = true
	$GFX/SpriteAccent.visible = true
	$GFX/SpriteClothes.visible = true
	GlobalRuntime.snap_to_grid( position )
	animation_tree.active = true
	update_anim_tree()
	
	if monster == null:
		var _umid = umid
		monster = Monster.new()
		monster.umid = _umid
	
	GlobalDatabase.update_gamepiece(self)
	_update_monster()
	kill_imposters()
	
	GlobalRuntime.pause_gameworld.connect( _on_gameworld_pause )
	GlobalRuntime.unpause_gameworld.connect( _on_gameworld_unpause )
	print("GP: I think I'm at ", current_position, " as ", tag)
	if tag == "player" or monster.umid <= 1:
		treat_as_player = true
		#is_local_player = false


func _process(_delta):	
	if not is_paused:
		if move_queue.size() > 0 && is_moving == false:
			move( (move_queue.pop_front() as Movement) )
		elif is_moving == true:
			was_moving = true
		elif was_moving == true: # implied: is_moving is false
			update_anim_tree()
			was_moving = false
	if is_moving and not was_moving:
		my_camera.tween_duration = GlobalRuntime.CAMERA_TWEEN_DURATION
		gamepiece_moving_signal.emit()
	elif not was_moving and not is_moving:
		gamepiece_stopped_signal.emit()


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
	#block_ray.target_position = direction * GlobalRuntime.DEFAULT_TILE_SIZE
	#block_ray.force_raycast_update()
	
	event_ray.target_position = direction * GlobalRuntime.DEFAULT_TILE_SIZE
	event_ray.force_raycast_update()
	event_ray.clear_exceptions()


func move( direction ):
	if (direction is Vector2 and direction == Vector2.ZERO) or \
		(direction is Vector2i and direction == Vector2i.ZERO):
		return
	if not direction is Movement:
		direction = Movement.new(direction, traversal_mode)
	
	traversal_mode = direction.method
	direction = direction.to_cell_vector2f()
	
	facing_direction = direction
	
	#_check_exterior_event_collision(direction)
	#var gfx_pos_prior = gfx.global_position
	var scaled_direction = GlobalRuntime.snap_to_grid_corner_f(direction * GlobalRuntime.DEFAULT_TILE_SIZE)
	#var test_transform = self.global_transform
	#test_transform.x.x = 0.8
	#test_transform.y.y = 0.8
	#test_transform.origin += (GlobalRuntime.DEFAULT_TILE_OFFSET * (1 - 0.8) )
	var would_collide = _peek_exterior_collision(direction)
	
	
	if not would_collide: 
		
		var colliding_within
		update_rays(direction)
		if event_ray.is_colliding():
			colliding_within = event_ray.get_collider()
		
		var new_position = GlobalRuntime.snap_to_grid(collision.position + \
			scaled_direction )
		
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
		colliding_within.is_in_group("event_on_entry") and \
		colliding_within.has_method("run_event"):
			colliding_within.run_event( self )
	else:
	#if would_collide:
		print("I don't think I can move to there...", scaled_direction + global_position, 
				" % ", scaled_direction, "\n\t\ttrans ", self.transform, ";", self.global_transform)
	is_moving = false
	traversal_mode = TraversalMode.STANDING
	
	## Used to check for event after moving... is it actually used/useful?
	#var normalized_direction = direction.normalized() * GlobalRuntime.DEFAULT_TILE_SIZE
	_check_touch_event_collision(direction)


##	Check for touching the surface of an adjecent object/cell
##	
##	parameters:
##		direction - the predicted direction of the object collided with
func _check_touch_event_collision(direction:Vector2):
	update_rays(direction)
	
	while event_ray.is_colliding():
		var colliding_with = event_ray.get_collider()
		if colliding_with.is_in_group("event_on_touch") and colliding_with.has_method("run_event"):
			colliding_with.run_event( self )
		if colliding_with is CollisionObject2D:
			event_ray.add_exception(colliding_with)
			print(colliding_with)
		await get_tree().process_frame
	pass


func _peek_exterior_collision(direction:Vector2):
	const TEST_TRANSFORM_RESCALE := 0.8
	var scaled_direction = GlobalRuntime.snap_to_grid_corner_f(direction * GlobalRuntime.DEFAULT_TILE_SIZE)
	var test_transform = self.global_transform
	test_transform.x.x = TEST_TRANSFORM_RESCALE
	test_transform.y.y = TEST_TRANSFORM_RESCALE
	test_transform.origin += (GlobalRuntime.DEFAULT_TILE_OFFSET * (1 - TEST_TRANSFORM_RESCALE) )
	return test_move( test_transform, scaled_direction, null, 0 )


func _update_monster():
	var mon = GlobalDatabase.load_monster( umid )
	if mon:
		monster = mon
	
	update_sprites()


func update_sprites():
	
	# tag = monster's tag, for semantic calling on generic sprites
	var _tag = GlobalDatabase.fetch_dex_from_index(monster.species, ["tag"]).pop_front()
	if _tag is Dictionary:
		_tag = _tag["tag"]
	if _tag == null or _tag == "":
		_tag = "default"
	
	_update_sprites(_tag)
	
	# Guard clause before de-genericizing the gamepiece
	if self.tag == null:
		return
	_tag = self.tag # set tag to that of the specific character
	
	_update_sprites(_tag, false)
	# Overwrite previous changes, but only where a replacement layer exists


func _update_sprites(_tag:String, clear_prev:=true):
	
	# Guard clause, avoid wasting time on failed cases
	# (slightly increases delay on successful cases?)
	if _tag == null or _tag.strip_edges() == "":
		return
	
	# Clear Prev marks whether the sprite is extending a previous load,
	# or regenerating from scratch. The former removes the default dress,
	# and the latter adds character-specific dress (if coded correctly).
	if clear_prev:
		gfx.find_child("SpriteAccent").texture = null
		gfx.find_child("SpriteBase").texture = null
		gfx.find_child("SpriteClothes").texture = null
	
	var addr_accent = str("res://assets/textures/mon/overworld/", _tag ,"/accent.png")
	var addr_base = str("res://assets/textures/mon/overworld/", _tag ,"/base.png")
	var addr_dress = str("res://assets/textures/mon/overworld/", _tag ,"/dress.png")
	
	# Check the accent layer, which includes patterns, markings, hair, etc.
	# This is first alphabetically; order shouldn't matter greatly
	if FileAccess.file_exists(addr_accent):
		var sprite_accent = load(addr_accent)
		if sprite_accent != null:
			gfx.find_child("SpriteAccent").texture = sprite_accent
	else:
		print( addr_accent, " not found! gp line 303 - accent ", _tag )
	
	# Check the base layer, which includes most of the body, ideally
	# This is second alphabetically; order shouldn't matter greatly
	if FileAccess.file_exists(addr_base):
		var sprite_base = load(addr_base)
		if sprite_base != null:
			gfx.find_child("SpriteBase").texture = sprite_base
	else:
		print( addr_base, " not found! gp line 308 - base ", _tag )
		if _tag != "default" and clear_prev:
			_update_sprites("default") 
			# If the current tag cannot be found, the sprite has to be made visible.
			# Therefore, set it to the default tag, which should exist.
			# If the default tag does not exist, either this is an unstable branch...
			# ... or we have much bigger problems than fetching a single sprite.
	
	# Check the dress layer, which includes clothing.
	# This is third alphabetically; order shouldn't matter greatly
	if FileAccess.file_exists(addr_dress):
		var sprite_dress = load(addr_dress)
		if sprite_dress != null:
			gfx.find_child("SpriteClothes").texture = sprite_dress
	else:
		print( addr_dress, " not found! gp line 315 - dress ", _tag )


##	Not the same as move, used for in-map teleportation.
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
	#print("gp ", umid, "/", unique_id, " global position ~ ", current_position)
	
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
	var camera_tween_prior = my_camera.tween_duration
	my_camera.tween_duration = 0
	
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
	
	my_camera.tween_resource.duration = 0
	
	shift_to_target( loci )
	facing_direction = Vector2( direction.x, direction.y )
	
	print("teleport: gx %d, gy %d, x %d, y %d"%[global_position.x,global_position.y,loci.x,loci.y])
	
	if GlobalRuntime.scene_manager.phantom_camera_host._active_pcam_2d == my_camera:
		GlobalRuntime.scene_manager.phantom_camera_host._prev_active_pcam_2d_transform.origin = global_position
	my_camera.tween_resource.duration = GlobalRuntime.CAMERA_TWEEN_DURATION
	controller.finalize_map_change( pause_prior, silent )


# Among Us reference?
# Remove or modify other gamepieces which are too similar, to halt player cloning
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
