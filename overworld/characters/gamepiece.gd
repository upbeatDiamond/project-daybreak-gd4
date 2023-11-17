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
@onready var event_ray = $Collision/EventRayCast2D
@onready var gfx = $GFX
@onready var shadow = $GFX/Shadow
@onready var collision = $Collision
@onready var controller = $Controller
@onready var move_tween : Tween

var is_paused = false;	# true if cannot act
var is_moving = false;	# true if walking, running, jumping, etc
var position_is_known = true;	# false if the gamepiece needs a new position calculated.
var facing_direction = Vector2(0,0);	# Used for animation state tree

var traversal_mode = TraversalMode.STANDING

enum TraversalMode
{
	STANDING, 	# 🧍‍♀️ 
	WALKING, 	# 🚶‍♀️ 
	RUNNING, 	# 🏃‍♂️ 
	TRUDGING, 	# 
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
		
		# Before this match is run, try looking for materials that change the character's...
		# ... speed or animation, and change the traversal mode to match.
		
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


func set_teleport(loci: Vector2i, direction: Vector2i, map:=""):
	is_moving = false
	
	if map.length() > 0:
		controller.handle_map_change( map )
	
	loci = snap_to_grid( loci )
	move_to_target( loci ) # This line might be redundant.
	facing_direction = Vector2( direction.x, direction.y )
	
	print("teleport to gx %d, gy %d, x %d , y %d" % [global_position.x, global_position.y, loci.x, loci.y])


static func gamepiece_from_walker( walker:GamepieceWalker ) -> Gamepiece:
#	var new_gamepiece = Gamepiece.new()
#	new_gamepiece.collision_layer = 1		# Not a big fan of this line. Try tying it to something.
#	new_gamepiece.name = "Gamepiece"
#
#	var new_controller = Node.new()
#	new_controller.set_script( walker.controller )
#	new_gamepiece.add_child( new_controller )
#	new_controller.name = "Controller"
#
#	var new_collision = CollisionShape2D.new()
#	new_collision.shape = RectangleShape2D.new()
#	new_collision.shape.size = Vector2( GlobalRuntime.DEFAULT_TILE_SIZE, GlobalRuntime.DEFAULT_TILE_SIZE )
#	new_gamepiece.add_child( new_collision )
#	new_collision.name = "Collision"
#	new_collision.position = Vector2( 8, 8 )
#	var new_event_ray = RayCast2D.new()
#	new_event_ray.collision_mask = 4		# Not a big fan of this line. Try tying it to something.
#	new_collision.add_child(new_event_ray)
#	new_event_ray.name = "EventRayCast2D"
#	var new_block_ray = RayCast2D.new()
#	new_block_ray.collision_mask = 3		# Not a big fan of this line. Try tying it to something.
#	new_collision.add_child(new_block_ray)
#	new_block_ray.name = "LedgeRayCast2D"
#
#	var new_gfx = Marker2D.new()
#	new_gamepiece.add_child( new_gfx )
#	new_gfx.name = "GFX"
#	var new_shadow = Sprite2D.new()
#	new_gfx.add_child( new_shadow )
#	new_shadow.name = "Shadow"
#	var new_sprite = Sprite2D.new()
#	new_gfx.add_child( new_sprite )
#	new_sprite.name = "Sprite"
#	new_sprite.texture = load("res://player/player_base_move.png")
#	new_sprite.hframes = 7
#	new_sprite.vframes = 4
#	new_sprite.position = Vector2(8,0)

	# Should I remove the above yet? Maybe not. It could be nice to recycle. Maybe put it on the scrapheap.
	
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
	
	pass

static func walker_from_gamepiece( gamepiece:Gamepiece ) -> GamepieceWalker:
	
	var walker = GamepieceWalker.new( gamepiece.monster,
										gamepiece.controller.get_script(),
										gamepiece.get_current_map_id(),
										gamepiece.target_map,
										gamepiece.target_position )
	
	return walker
	
	pass
