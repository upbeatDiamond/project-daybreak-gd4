extends Marker2D

#var room_position:Vector2i
var room_size: Vector2i
var room_size_half: Vector2i
var room_size_third: Vector2i

enum Flags{
	NORTH_ACCESS,	# represents both "can access ..."/"can be accessed by ..."
	EAST_ACCESS,
	SOUTH_ACCESS,
	WEST_ACCESS,
	
	NORTH_WALL,		# used to connect two rooms. If access & !wall: closed door w/ no wall 
	EAST_WALL,
	SOUTH_WALL,
	WEST_WALL,
	
	NORTHEAST_JUT,	# used to diversify playspace, may be replaced/changed.
	SOUTHEAST_JUT,  # If jut but no wall, jut takes priority
	SOUTHWEST_JUT,
	NORTHWEST_JUT
}

# It's probably a bad idea to have the enum and variable have the same name.
# Or maybe it's the best idea and I use it nowhere else yet.
var bitfield := 0
var is_ready := false
var _backrooms: TileMap
#var environment: TileMap 
# Redundant? Maybe. Better code that works than code that saves that extra inch.
# Although inches add up...

func _ready():
	while _backrooms == null:
		#_backrooms = environment
		print("why is the floor missing? Try again!")
	
	if not Engine.is_editor_hint():
		_backrooms = get_parent() as TileMap
		assert(_backrooms, "The FailsafeRoom must have a TileMap as a parent. "
			+ "%s is not a tilemap!" % get_parent().name)
	is_ready = true


func _init( room_size, environment ):
	
	var northways = randi_range(0,1) as bool
	var eastways = randi_range(0,1) as bool
	var southways = randi_range(0,1) as bool
	var westways = randi_range(0,1) as bool
	
	eastways = eastways || !(northways && westways && southways)
	#southways = southways || !(northways && westways && eastways)
	
	GlobalBitManip.update_bitfield_flag( bitfield, Flags.NORTH_ACCESS, northways );
	GlobalBitManip.update_bitfield_flag( bitfield, Flags.EAST_ACCESS, eastways );
	GlobalBitManip.update_bitfield_flag( bitfield, Flags.SOUTH_ACCESS, southways );
	GlobalBitManip.update_bitfield_flag( bitfield, Flags.WEST_ACCESS, westways );
	
	GlobalBitManip.update_bitfield_flag( bitfield, Flags.NORTH_WALL, randi_range(0,1) );
	GlobalBitManip.update_bitfield_flag( bitfield, Flags.EAST_WALL, randi_range(0,1) );
	GlobalBitManip.update_bitfield_flag( bitfield, Flags.SOUTH_WALL, randi_range(0,1) );
	GlobalBitManip.update_bitfield_flag( bitfield, Flags.WEST_WALL, randi_range(0,1) );
	
	self.room_size = room_size
	self.room_size_half = (room_size + Vector2i.ONE)/2
	self.room_size_third = (room_size + Vector2i.ONE)/3
	self._backrooms = environment
	
	pass



func set_properties( flags:int, mask:int ):
	pass

func print_all_properties():
	for flag in Flags.values():
		print("Okay! Printing %d" % flag)
		print_property( flag, GlobalBitManip.get_bitflag(bitfield, flag), true ) # flag==0
	
	pass


func make_clone_of( room ):
	self.bitfield = room.bitfield
	set_properties( bitfield, GlobalBitManip.invert(0) )
	pass


func set_neighbor_of( room ):
	# If same x position, but different y positions...
	if room.position.x == self.position.x && (  abs(self.position.y-room.position.y) < 2*room_size.y  ):
		# if neighbor is to the left...
		var ns_wall
		if room.position.y <= self.position.y:
			ns_wall = GlobalBitManip.get_bitflag(room.bitfield, Flags.SOUTH_WALL) & GlobalBitManip.get_bitflag(self.bitfield, Flags.NORTH_WALL)
			room.bitfield = GlobalBitManip.set_bitflag( room.bitfield, Flags.SOUTH_WALL, ns_wall )
			bitfield = GlobalBitManip.set_bitflag( bitfield, Flags.NORTH_WALL, ns_wall )
		else:
			ns_wall = GlobalBitManip.get_bitflag(room.bitfield, Flags.NORTH_WALL) & GlobalBitManip.get_bitflag(self.bitfield, Flags.SOUTH_WALL)
			room.bitfield = GlobalBitManip.set_bitflag( bitfield, Flags.SOUTH_WALL, ns_wall )
			bitfield = GlobalBitManip.set_bitflag( bitfield, Flags.NORTH_WALL, ns_wall )
			pass 
	# If same y position, but different x positions...
	elif room.position.y == self.position.y && (  abs(self.position.x-room.position.x) < 2*room_size.x  ):
		# if neighbor is to the left...
		var we_wall
		if room.position.x <= self.position.x:
			we_wall = GlobalBitManip.get_bitflag(room.bitfield, Flags.WEST_WALL) & GlobalBitManip.get_bitflag(self.bitfield, Flags.EAST_WALL)
			bitfield = GlobalBitManip.set_bitflag( bitfield, Flags.WEST_WALL, we_wall )
			room.bitfield = GlobalBitManip.set_bitflag( room.bitfield, Flags.EAST_WALL, we_wall )
		else:
			we_wall = GlobalBitManip.get_bitflag(room.bitfield, Flags.EAST_WALL) & GlobalBitManip.get_bitflag(self.bitfield, Flags.WEST_WALL)
			bitfield = GlobalBitManip.set_bitflag( bitfield, Flags.WEST_WALL, we_wall )
			room.bitfield = GlobalBitManip.set_bitflag( room.bitfield, Flags.EAST_WALL, we_wall )
			pass 
	# If same x and y, or too far apart...
	else:
		pass
	pass




# The one time I'm using a 'bool' type this month.
# void set_cells_terrain_connect ( int layer, Vector2i[] cells, int terrain_set, int terrain, bool ignore_empty_terrains=true )
func print_property( flag:Flags, value, wipe:int ):
	#print("Will I wipe? %d" % wipe)
	
	# Replaces empty or garbage square with full carpet
	if wipe>0:
		var tile_zone = []
		for i in range(0, room_size.x):
			for j in range(0, room_size.y):
				tile_zone.append( Vector2i(i+position.x,j+position.y) )
		_backrooms.set_cells_terrain_connect( 0, tile_zone, 1, 1, true )
	
	# Creates an incomplete north wall
	if GlobalBitManip.get_flag_bit( bitfield, Flags.NORTH_WALL ):
		var tile_zone = []
		#for i in range(0, room_size.x):
		for i in range(0, room_size.x):
			if (i > room_size.x-room_size_third.x || i <= room_size_third.x):
				tile_zone.append( Vector2i(position.y,i+position.x) )
		_backrooms.set_cells_terrain_connect( 0, tile_zone, 1, 0, true )
		pass
	
	# Creates a north door blockage
	if !GlobalBitManip.get_flag_bit( bitfield, Flags.NORTH_ACCESS ):
		var tile_zone = []
		#for i in range(0, room_size.x):
		for i in range(0, room_size.x):
			if (i < room_size.x-room_size_third.x && i >= room_size_third.x):
				tile_zone.append( Vector2i(position.y,i+position.x) )
		_backrooms.set_cells_terrain_connect( 0, tile_zone, 1, 0, true )
		pass
	
	pass
