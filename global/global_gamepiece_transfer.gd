extends Node

enum MapIndex {
	# All references to these indexes should be through this enum in case of value reassignments
	# Also in case of reassignment mismatches, avoid reassigning any enums.
	# Generally ordered by ownership tier: Town{ Building{}, Road{ NookSmol{} }, NookBig{} }

	INVALID_INDEX = -1,
	TOWN_RED,		# Story gets going town, visited 2nd
	TOWN_RESERVE_000,	# Might be merged with TOWN_GREEN ? or recycled...
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
	TOWN_PEAK,
	
	# Items above represent towns/caves/plains and need exactly 2 words
	# There can be up to 255 values between Invalid and Windmill
	# If extensions are needed (please no), then values at the end of the list can be used.
	
	TOWN_PORT_WINDMILL = 256,
	TOWN_PORT_MUSEUM,
	TOWN_HOME_HOME,
	TOWN_HOME_LAB,
	TOWN_RED_GYM,
	TOWN_GREEN_GYM,
	TOWN_BLUE_GYM,
	TOWN_SCRATCH_GYM,
	TOWN_PORT_GYM,
	TOWN_FIRE_GYM,
	TOWN_MASTIC_GYM,
	TOWN_ORACLE_GYM,
	TOWN_FISH_GYM,
	TOWN_THUNDER_GYM,
	TOWN_THUNDER_CHURCH_EAST,
	TOWN_THUNDER_CHURCH_WEST,
	TOWN_BROWN_GYM,
	TOWN_TECH_GYM,
	TOWN_SNOWBALL_GYM,
	TOWN_ZEPHYR_GYM,
	TOWN_METAL_GYM,
	TOWN_METAL_MINESHAFT,
	TOWN_FOREST_GYM,
	TOWN_PEAK_GYM,
	
	
	# Items above represent buildings and interiors subordinate to towns/caves, and need 3 words
	# There can be up to 2048 values between Invalid and Route Home->Red
	# If extensions are needed (please please no), then values at the end of the list can be used.
	
	ROUTE_HOME_TO_RED = 2048,
	ROUTE_RED_TO_GREEN,
	ROUTE_RED_TO_FIRE,
	ROUTE_FIRE_TO_FOREST,
	ROUTE_FIRE_TO_SCRATCH,
	ROUTE_FIRE_TO_MASTIC,
	ROUTE_SCRATCH_TO_MASTIC,
	ROUTE_MASTIC_TO_ORACLE,
	ROUTE_GREEN_TO_PORT,
	ROUTE_PORT_TO_FOREST,
	ROUTE_PORT_TO_ZEPHYR,
	ROUTE_PORT_TO_THUNDER,
	ROUTE_THUNDER_TO_FISH,
	ROUTE_FISH_TO_BLUE,
	ROUTE_BLUE_TO_BROWN,
	ROUTE_BROWN_TO_PEAK,
	ROUTE_ZEPHYR_TO_FOREST,
	ROUTE_ZEPHYR_TO_SNOWBALL,
	ROUTE_SNOWBALL_TO_BROWN,
	ROUTE_SNOWBALL_TO_TECH,
	ROUTE_TECH_TO_METAL,
	ROUTE_METAL_TO_NORTH_CAVE,
	
	# There can be an unlimited*[1] number of routes and niches/nooks/hideyholes
	# All routes and nooks need at least 4 words, including where they come from and lead to...
	# ... unless using an initial word not used for any nook/routes, in which 2 are needed.
	# Route: ROUTE [source, or south, or near home] TO [destination, or north, or faraway]
		#ex: ROUTE_SOUTH_TO_NORTH
		#ex: ROUTE_UNDERSEA_CAVE
	# Nook: [town/route/cave/etc] [temp name] [nearest building/interior] [nook identity]
		#ex: CAVE_NORTH_BOSS_NEST
		#ex: ISLE_MYSTERY
	# *[1] - by "unlimited", I mean around 9223372036854773760 if we ignore DLC and mods.
	
	# From this point forward are identifiers that are extremely likely to change value.
	
	MAX_VALUE,
	# From this point on is compatibility aliases (As in, please phase these out, but carefully.)
	
	FAILSAFE_ROOM = INVALID_INDEX,
	TOWN_MAUVE = TOWN_RESERVE_000,
}

var gamepiece_preload = preload( "res://overworld/characters/gamepiece.tscn" )


# Gamepieces should be made much smaller before storing, but there's only the player now, so eh.
func submit_gamepiece( piece:Gamepiece, target_map_index:MapIndex, \
target_map_coordinates:=Vector2i(0,0), _origin_map_index:=MapIndex.INVALID_INDEX ):
	
	if piece != null:
		piece.current_map = _origin_map_index
		piece.target_map = target_map_index
		piece.position_stabilized = false
		if piece.current_map == MapIndex.INVALID_INDEX:
			piece.current_map = piece.target_map
	
	piece.target_position = target_map_coordinates
	
	if target_map_index >= 0:
		
		if piece.get_parent() != null:
			piece.get_parent().remove_child( piece )
	
	GlobalDatabase.save_gamepiece( piece )
	pass


# If gp_id == -1, then ignore it.
# Assumes you want to retrieve from the cache
# If there's a cache fail and check_table == true, then check the db
# There shouldn't be duplication of gamepieces in general, so besides linear search time, this good
func pop_out_gamepiece( umid:int, gp_id:int=-1, check_table:=false ) -> Gamepiece:
	var piece := eject_gamepiece(umid)
	return piece


func save_map_gamepieces( _map:LevelMap ):
	await _save_map_placed_gamepieces(_map)


func _save_map_placed_gamepieces( _map:LevelMap ):
	
	for gp in GlobalRuntime.scene_manager.get_tree().get_nodes_in_group("gamepiece"):
		if is_instance_valid(gp) and gp is Gamepiece: # Check for if freed before saving
			GlobalDatabase.save_gamepiece( gp as Gamepiece )
		elif not is_instance_valid(gp):
			print("PIECE ALREADY FREED")


# When playing multiplayer, or even singleplayer, and an NPC/Guest changes to your map?
# Detect that happened and warp them into your current map.
# Else, make sure they're saved in the relevant database.
func warp_gamepiece_to_map( _map_index:MapIndex ):
	pass


func eject_gamepieces_for_map( target_map_index:int ) -> Array[Gamepiece]:
	var gamepieces = GlobalDatabase.load_gamepieces_for_map( target_map_index )
	return gamepieces


func save_placed_gamepieces():
	var tree = GlobalRuntime.scene_manager.get_tree()
	var gamepieces = tree.get_nodes_in_group("gamepiece")
	var maps = tree.get_nodes_in_group("level_map")
	var map = MapIndex.INVALID_INDEX
	if maps.size() >= 1:
		map = maps[0].get("map_index")
	for piece in gamepieces:
		if piece is Gamepiece:
			save_gamepiece(piece, map, piece.position, map)


func save_gamepiece( piece:Gamepiece, target_map_index:MapIndex, \
target_map_coordinates:=Vector2i(0,0), _origin_map_index:=MapIndex.INVALID_INDEX ):
	
	if piece != null:
		piece.current_map = _origin_map_index
		piece.target_map = target_map_index
		piece.position_stabilized = false
		if piece.current_map == MapIndex.INVALID_INDEX:
			piece.current_map = piece.target_map
	
	piece.target_position = target_map_coordinates
	
	if piece.get_parent() != null:
		piece.get_parent().remove_child( piece )
	
	GlobalDatabase.save_gamepiece( piece )


func eject_gamepiece( umid:int ) -> Gamepiece:
	var gamepiece = GlobalDatabase.load_gamepiece(umid)
	return gamepiece
