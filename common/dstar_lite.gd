extends Node
class_name DStarLite

const CUSTOM_DATA_NAME = "DStarBitfield"
const CUSTOM_DATA_NAME_COST = "DStarCost"

# I feel like I already defined this somwehere, but where...?
enum Bitfield
{
	# Standard access methods
	NORTH_BLOCKED,		# Can move 'up'
	EAST_BLOCKED,		# Can move 'left'
	SOUTH_BLOCKED,		# Can move 'down'
	WEST_BLOCKED,		# Can move 'right'
	NORTHEAST_BLOCKED,	# Can move 'up' and 'left', ignored for Manhatten mode
	SOUTHEAST_BLOCKED,	# Can move 'down' and 'left', ignored for Manhatten mode
	SOUTHWEST_BLOCKED,	# Can move 'down' and 'right', ignored for Manhatten mode
	NORTHWEST_BLOCKED,	# Can move 'up' and 'right', ignored for Manhatten mode
	# No, we're not checking bits for all 3x3x3-1 potential neighbors

	# Non-standard (or oft ignored) access methods
	SELF_BLOCKED,		# Does not determine passibility, but targetibility; can it be rested on?
	UPWARDS_BLOCKED,	# Can move 'out', to a higher layer, unused
	DOWNWARDS_BLOCKED,	# Can move 'in', to a lower layer, unused
	RESERVED_1_1,
	RESERVED_1_2,
	RESERVED_1_3,
	RESERVED_1_4,
	RESERVED_1_5,
	RESERVED_1_6,
	
	# Metametadata - Ya ya hayiyiyi-ya! You have much yet to learn.
	OUTLINK_EXPECTED,	# Used if tile is intended to act as a door/portal/teleport
}

var k_m := 0 # I have no idea what k_m means.
var s_start : Vector2i
var s_last : Vector2i
var s_goal : Vector2i
var s_next : Vector2i
var u : DStarStorage
var rhs : DStarStorage
var g : DStarStorage
var board : TileMap

var heuristic := HeuristicMode.MANHATTEN
var diagonals_enabled = false

@onready var collider : Area2D

func _init( board:TileMap, collision_mask:int ):
	self.board = board
	
	collider = Area2D.new()
	
	var collide_shape = CircleShape2D.new()
	collide_shape.radius = GlobalRuntime.DEFAULT_TILE_SIZE / 2.0
	var collider_shape = CollisionShape2D.new()
	collider_shape.set_shape( collide_shape )
	collider.add_child( collider_shape )
	
	#collider.init()
	collider.monitorable = false
	collider.monitoring = true
	
	set_collision_mask( collision_mask )
	
	pass

# Determines distance cost measure
enum HeuristicMode
{
	MANHATTEN,
	EUCLIDEAN
}

func set_collision_mask( collision_mask : int ):
	collider.collision_mask = collision_mask
	pass

func calculate_key(s):
	return min( cost_so_far(s), right_hand_side(s) ) + heuristic_cost(s_start, s) + k_m; #min(cost_so_far(s), right_hand_side(s))
	pass

# It's supposed to be 'initialize', but that sounds too much like 'init'.
func new_path(s_start, s_goal, grid:=board):
	u = DStarStorage.new()
	g = DStarStorage.new()
	rhs = DStarStorage.new()
	self.s_start = s_start
	self.s_last = s_start
	self.s_goal = s_goal
	k_m = 0
	board = grid
	# We will assume that all vectors represent positions...
	# ... and all vectors by default are g(s) = infinity
	# We will also start with rhs(s_goal) = 0
	rhs.insert(s_goal, 0)
	u.insert(s_goal, heuristic_cost(s_start, s_goal));
	compute_shortest_path();
	pass

## Original write-up's line 37" (optimized version)
## Any agents should use this upon getting a signal about path changes
#func update_path_edges( edges:Array[Vector2i] ):
#	k_m = k_m + heuristic_cost(s_last, s_start)
#	s_last = s_start;
#	for edge in edges:
#		# Issue: the paper mentions directed edges...
#		# Uhhhhhh how am I going to work that out?
#		# Best to just not update any edges for now.
#		#var c_old = get_cell_weight(edge)
#		pass
#	pass

# The 'h' function
# 'goal' here is not 'final goal', but current 'target' cell.
# code may change for clarity later
func heuristic_cost(s, goal):
	
	match heuristic:
		HeuristicMode.MANHATTEN:
			return abs(s.x - goal.x) + abs(s.y - goal.y)
			pass
		HeuristicMode.EUCLIDEAN:
			return sqrt( pow(s.x - goal.x, 2) + pow(s.y - goal.y, 2) )
			pass

# The 'rhs' function
func right_hand_side( s ):
	return rhs.get_key(s)
	pass

# The 'g' function
func cost_so_far( s ):
	return g.get_key(s)
	pass

# Validates cell, mainly checking collision.
func validate_cell_collision( cell ):
	collider.position.x = GlobalRuntime.DEFAULT_TILE_SIZE*cell.x
	collider.position.y = GlobalRuntime.DEFAULT_TILE_SIZE*cell.y
	return !collider.has_overlapping_bodies()
	pass
	# Please check for object group in future versions, to allow for multi-layer.

# Returns list of cells that can be walked to from the input cell
func get_valid_successors( cell ):
	var successors := []
	var current
	
	current = cell + Vector2i(0,-1); validate_cell_reusable( current, current, Bitfield.SOUTH_BLOCKED, successors )
	current = cell + Vector2i(0, 1); validate_cell_reusable( current, current, Bitfield.NORTH_BLOCKED, successors )
	current = cell + Vector2i(1, 0); validate_cell_reusable( current, current, Bitfield.WEST_BLOCKED,  successors )
	current = cell + Vector2i(-1,0); validate_cell_reusable( current, current, Bitfield.EAST_BLOCKED,  successors )

	if (diagonals_enabled):
		current = cell + Vector2i(1, -1); validate_cell_reusable( current, current, Bitfield.SOUTHWEST_BLOCKED, successors )
		current = cell + Vector2i(-1, 1); validate_cell_reusable( current, current, Bitfield.NORTHEAST_BLOCKED, successors )
		current = cell + Vector2i(1,  1); validate_cell_reusable( current, current, Bitfield.NORTHWEST_BLOCKED, successors )
		current = cell + Vector2i(-1,-1); validate_cell_reusable( current, current, Bitfield.SOUTHEAST_BLOCKED, successors )

	return successors

	pass
	# Return based on access bitfield, verify with is_cell_noncolliding()

# Dumb name because it has a stupidly simple purpose:
# Don't Resue Code, or whatever the acronym is.
func validate_cell_reusable( cell_bitcheck, cell_collide, bitcompare:int, successors:Array ):
		# For-loop that doesn't rely on making an array in the background.
	var current = 0
	var bitpile = 0
	
	if board != null:
		var i = board.get_layers_count() - 1
		while (i > -1):
			current = board.get_cell_tile_data( i, cell_bitcheck )
			if current != null:
				current = current.get_custom_data(CUSTOM_DATA_NAME)
				if current != null:
					bitpile = bitpile | current
			i = i - 1
		
	if (bitpile & (1 << bitcompare) == 0):
		if validate_cell_collision( cell_collide ):
			successors.append( cell_bitcheck )
			#return cell
	pass


# Returns list of cells that have access to the input cell
func get_valid_predecessors( cell ) -> Array:
	
	var successors := []
	var current
	
	current = cell + Vector2i(0,-1); validate_cell_reusable( cell, current, Bitfield.NORTH_BLOCKED, successors )
	current = cell + Vector2i(0, 1); validate_cell_reusable( cell, current, Bitfield.SOUTH_BLOCKED, successors )
	current = cell + Vector2i(1, 0); validate_cell_reusable( cell, current, Bitfield.EAST_BLOCKED,  successors )
	current = cell + Vector2i(-1,0); validate_cell_reusable( cell, current, Bitfield.WEST_BLOCKED,  successors )
	
	if (diagonals_enabled):
		current = cell + Vector2i(1, -1); validate_cell_reusable( cell, current, Bitfield.NORTHEAST_BLOCKED, successors )
		current = cell + Vector2i(-1, 1); validate_cell_reusable( cell, current, Bitfield.SOUTHWEST_BLOCKED, successors )
		current = cell + Vector2i(1,  1); validate_cell_reusable( cell, current, Bitfield.SOUTHEAST_BLOCKED, successors )
		current = cell + Vector2i(-1,-1); validate_cell_reusable( cell, current, Bitfield.NORTHWEST_BLOCKED, successors )
	
	return successors
	# Similar to get...succ...() but checking the neighbors' bitfields.

# depricated & unfinished
func replace_target():
	# Change 's_goal' position, calculate new path
	pass

# the 'c' function
func get_cell_weight( cell : Vector2i ):
	var w = null
	var i;
	if board != null: 
		i = board.get_layers_count() - 1
		while (i > -1):
			w = board.get_cell_tile_data( i, cell )
			if w != null:
				w = w.get_custom_data(CUSTOM_DATA_NAME_COST)
				if w != null:
					return w
			i = i - 1
	return 100 #DStarStorage.INTEGER_INF


func pop_next_cell() -> Vector2i:
	load_next_cell()
	s_last = s_start;
	s_start = s_next;
	return s_start;
	pass


# procedure Main, but only the first loop's contents
# pop_next_cell, minus the popping
func load_next_cell() -> Vector2i:
	if (s_start != s_goal):
		s_next = arg_min( s_start ).element
		#s_next = s_start_min.x as int
		#s_next.y = s_start_min.y as int
		return s_next
	return s_goal

# subset of procedure Main
# gets valid successors of 'cell', and returns min of [c(cell,succ) + g(succ)]
func arg_min( cell:Vector2i ):
	var successors = get_valid_successors(cell)
	#var rhs_candidates := []
	var store = DStarStorage.new()
	
	for succ in successors:
		store.insert( succ, get_cell_weight(succ) + g.get_key(succ) )
		pass
	
	#store.sort_custom( Callable(DStarStorage, "compare") )
	
	return store.get_top()


func compute_shortest_path():
	var v
	var k_old
	var k_new
	var g_old
	while( u.top_key() < calculate_key(s_start) or right_hand_side(s_start) > cost_so_far(s_start)):
		v = u.top();
		k_old = u.top_key()
		k_new = calculate_key(v)
		if(k_old < k_new):
			u.update(v, k_new)
		elif( cost_so_far(v) > right_hand_side(v) ):
			g.update( v, right_hand_side(v) )
			u.remove( v )
			for s in get_valid_predecessors(v):
				if s != s_goal:
					rhs.update(s, min( right_hand_side(s), get_cell_weight(s) + cost_so_far(v)) )
					update_vertex(s)
			# For all successors of v, condit. update rhs & updatevertex()
		else:
			g_old = cost_so_far(v)
			g.remove( v )
			var predecessors = get_valid_predecessors(v)
			predecessors.append(v)
			for pred in predecessors:
				if( right_hand_side(pred) == get_cell_weight(pred) + g_old ):
					if( pred != s_goal ):
						rhs.update( pred, get_cell_weight(arg_min(pred)) )
				update_vertex(pred)
			# For all successors of v, condit. update rhs & updatevertex()
		pass
	pass

func update_vertex( v:Vector2i ):
	if( cost_so_far(v) != right_hand_side(v) and u.has(v) ):
		u.update(v, calculate_key(v))
	elif( cost_so_far(v) != right_hand_side(v) ):
		u.insert(v,calculate_key(v))
	elif( cost_so_far(v) == right_hand_side(v) and u.has(v) ):
		u.remove(v)
	pass
