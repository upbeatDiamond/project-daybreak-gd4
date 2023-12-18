extends Node

enum MapIndex
{
	# All references to these indexes should be through this enum in case of value reassignments
	# Also in case of reassignment mismatches, avoid reassigning any enums.
	# Generally ordered by ownership tier: Town{ Building{}, Road{ NookSmol{} }, NookBig{} }

	INVALID_INDEX = -1,
	TOWN_RED,		# Story gets going town, visited 2nd
	TOWN_MAUVE,		# Might be merged with TOWN_GREEN ? or recycled...
	TOWN_SCRATCH,
	TOWN_PORT,		# Hub town
	TOWN_HOME,		# Starting town, visited 1st
	TOWN_GREEN,
	TOWN_FIRE,		# They do pottery
	TOWN_MASTIC,	# Farming?
	TOWN_ORACLE,
	TOWN_FISH,
	TOWN_THUNDER,
	TOWN_BLUE,
	TOWN_BROWN,
	TOWN_TECH,
	TOWN_SNOWBALL,
	TOWN_ZEPHYR,
	TOWN_METAL,
	TOWN_FOREST,	# Exiting the forest is very simple, all you do is complete the gym badge
	CAVE_NORTH,
	CAVE_SOUTH,
	
	# Items above represent towns/caves/plains and need exactly 2 words
	# There can be up to 255 values between Invalid and Windmill
	
	TOWN_PORT_WINDMILL = 256,
	TOWN_PORT_MUSEUM,
	TOWN_HOME_HOME,
	
	# Items above represent buildings and interiors subordinate to towns/caves, and need 3 words
	# There can be up to 2048 values between Invalid and Route Home->Red
	
	ROUTE_HOME_TO_RED = 2048,
	
	# There can be an unlimited number of routes and niches/nooks/hideyholes
	# All routes and nooks need at least 4 words, including where they come from and lead to...
	# ... unless using an initial word not used for non nook/routes, in which 2 are needed.
	# Route: ROUTE [source, or south] TO [destination, or north]
		#ex: ROUTE_SOUTH_TO_NORTH
		#ex: ROUTE_UNDERSEA_CAVE
	# Nook: [town/route/cave/etc] [temp name] [nearest building/interior] [nook identity]
		#ex: CAVE_NORTH_BOSS_NEST
		#ex: ISLE_MYSTERY
	# From this point forward is enums that are extremely likely to change value.

	FAILSAFE_ROOM,

	# From this point on is compatibility aliases (As in, please phase these out, but carefully.)
}

var gamepieces_by_map : Array[Array] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

# Gamepieces should be made much smaller before storing, but there's only the player now, so eh.
func submit_gamepiece( piece:Gamepiece, target_map_index:MapIndex, \
target_map_coordinates:=Vector2i(0,0), origin_map_index:=MapIndex.INVALID_INDEX ):
	
	if gamepieces_by_map.size() < target_map_index:
		gamepieces_by_map.resize( target_map_index + 1 )
	
	if gamepieces_by_map[target_map_index] == null:
		gamepieces_by_map[target_map_index] = []
	
	gamepieces_by_map[target_map_index].append( piece )
	
	if piece.get_parent() != null:
		piece.get_parent().remove_child( piece )
	
	pass

#func retrieve_gamepiece( gp_id:int ) -> Gamepiece:
#	return null
#	pass

# When playing multiplayer, or even singleplayer, and an NPC/Guest changes to your map?
# Detect that happened and warp them into your current map.
# Else, make sure they're saved in the relevant database.
func warp_gamepiece_to_map(  ):
	pass

func eject_gamepieces_for_map( target_map_index:int ): #-> Array[Gamepiece]:
	if target_map_index < 0 || target_map_index >= gamepieces_by_map.size():
		return []
	else:
		var output = gamepieces_by_map[ target_map_index ]
		gamepieces_by_map[ target_map_index ] = []
		return output
	#pass
