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
	TOWN_PEAK,
	
	# Items above represent towns/caves/plains and need exactly 2 words
	# There can be up to 255 values between Invalid and Windmill
	# If extensions are needed (please no), then values at the end of the list can be used.
	
	TOWN_PORT_WINDMILL = 256,
	TOWN_PORT_MUSEUM,
	TOWN_HOME_HOME,
	TOWN_HOME_LAB,
	TOWN_RESERVE_001,
	TOWN_RESERVE_002,
	TOWN_RESERVE_003,
	TOWN_RESERVE_004,
	TOWN_RESERVE_005,
	TOWN_RESERVE_006,
	TOWN_RESERVE_007,
	TOWN_RESERVE_008,
	TOWN_RESERVE_009,
	TOWN_RESERVE_010,
	
	
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

	TOWN_RED_GYM,
	TOWN_GREEN_GYM,
	TOWN_BLUE_GYM,
	MAX_VALUE,
	# From this point on is compatibility aliases (As in, please phase these out, but carefully.)
	
	FAILSAFE_ROOM = INVALID_INDEX,
}

var gamepiece_preload = preload( "res://overworld/characters/gamepiece.tscn" )
#var gamepiece_player_preload = preload( "res://player/player.tscn" )
var gamepieces_by_map : Array[Array] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	gamepieces_by_map.resize( MapIndex.MAX_VALUE )
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

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
	
	if gamepieces_by_map.size() < target_map_index:
		gamepieces_by_map.resize( target_map_index + 1 )
	
	if target_map_index >= 0:
		
		if gamepieces_by_map == null:
			gamepieces_by_map = []
		
		if target_map_index >= gamepieces_by_map.size():
			gamepieces_by_map.resize( target_map_index + 1 )
		
		if gamepieces_by_map[target_map_index] == null:
			gamepieces_by_map[target_map_index] = []
		
		gamepieces_by_map[target_map_index].append( piece )
		
		if piece.get_parent() != null:
			piece.get_parent().remove_child( piece )
	
	GlobalDatabase.save_gamepiece( piece )
	pass

# Deprecated? If used, improve, else remove.
func reform_gamepiece_treelet( gamepiece:Gamepiece ):
	
	gamepiece.get_children()
	
	# Indirectly repair the 'gamepiece' variable / class object
	var gp_repair = gamepiece_preload.instantiate() as Gamepiece
	gp_repair.transfer_data_from_gp( gamepiece )
	
	# The ol' switcheroo!
	gamepiece = gp_repair
	
	var gamepiece_controller = gamepiece.find_child("Controller")
	if gamepiece.umid == 0:
		gamepiece_controller.set_script( "res://overworld/characters/gamepiece_controller_player.gd" )
		var player_cam = Camera2D.new()
		gamepiece.add_child( player_cam )
		player_cam.enabled = true
		player_cam.zoom = Vector2(2.5, 2.5)
		player_cam.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
		player_cam.position_smoothing_enabled = true
		player_cam.position_smoothing_speed = 5
	else:
		gamepiece_controller.set_script( "res://overworld/characters/gamepiece_controller_mob.gd" )
	
	gamepiece_controller.set("gamepiece", gamepiece)
	gamepiece.controller = find_child("Controller")
	
	return gamepiece


# If gp_id == -1, then ignore it.
# Assumes you want to retrieve from the cache
# If there's a cache fail and check_table == true, then check the db
# There shouldn't be duplication of gamepieces in general, so besides linear search time, this good
func pop_out_gamepiece( umid:int, gp_id:int=-1, check_table:=false ) -> Gamepiece:
	var piece_list := []
	for gamepieces in gamepieces_by_map:
		piece_list.append_array(gamepieces)
	for piece in piece_list:
		# If it exists, then gp_id == -1 (check umid) or != -1 (check gp_id)
		if piece != null and \
		((piece.umid == umid or gp_id != -1) and (gp_id == -1 or gp_id == piece.unique_id)):
			return piece
	if check_table:
		return GlobalDatabase.load_gamepiece( umid )
	return null


func save_map_gamepieces( _map:LevelMap ):
	_save_map_placed_gamepieces(_map)
	_save_map_stored_gamepieces(_map.map_index)


func _save_map_stored_gamepieces( _map_id:int ):
	if _map_id >= gamepieces_by_map.size():
		return
	for piece in gamepieces_by_map[_map_id]:
		GlobalDatabase.save_gamepiece( piece )


func _save_map_placed_gamepieces( _map:LevelMap ):
	for piece in _map.current_gamepieces:
		if piece is Gamepiece:
			GlobalDatabase.save_gamepiece( piece as Gamepiece )
	
	pass

# When playing multiplayer, or even singleplayer, and an NPC/Guest changes to your map?
# Detect that happened and warp them into your current map.
# Else, make sure they're saved in the relevant database.
func warp_gamepiece_to_map( _map_index:MapIndex ):
	pass


func eject_gamepieces_for_map( target_map_index:int ): #-> Array[Gamepiece]:
	if target_map_index < 0 || target_map_index >= gamepieces_by_map.size():
		return []
	else:
		var output = gamepieces_by_map[ target_map_index ]
		
		for piece in gamepieces_by_map[ target_map_index ]:
			piece.target_map = target_map_index
			piece.current_map = piece.target_map
			GlobalDatabase.save_gamepiece( piece )
		
		gamepieces_by_map[ target_map_index ] = []
		return output
	
