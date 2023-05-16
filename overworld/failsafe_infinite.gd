extends Node2D

# This is the "failsafe" program to "catch" "errors".
# Really though, this is an expression of pedantry and obstinacy.
# I have always held respect for hackers, speedrunners, and internet storywriters...
# ... so why not demonstrate that by punishing them with all 1 (one) (uno) (singular) Backrooms?
# Keeping with the original paragraph, who knows if there are monsters?
# Regardless, you're not getting out without knowing how you got in here.

const Matrix = preload("res://common/matrix.gd")
const Room = preload("res://overworld/failsafe_room.gd")

var room_matrix : Matrix
const ROOM_BOUNDS = Vector2i ( 16, 16 )
const ROOM_SIZE = Vector2i ( 16, 16 )

var is_even_more_ready := false

func _init():
	room_matrix = Matrix.new( ROOM_BOUNDS.x, ROOM_BOUNDS.y )
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	
#	pass # Replace with function body.


#func even_more_ready():
	# Step 1: Prepare matrix of rooms
	# Step 1a: build the initial rooms
	var new_room : Room
	
	for i in ROOM_BOUNDS.x:
		for j in ROOM_BOUNDS.y:
			new_room = Room.new( ROOM_SIZE )
			room_matrix.set_element( i, j, new_room )
			self.call_deferred("add_child", new_room );
			new_room.set_position( Vector2i(i*ROOM_SIZE.x, j*ROOM_SIZE.y) );
	
	# Step 1b: connect the rooms where appropriate
	for i in ROOM_BOUNDS.x:
		for j in ROOM_BOUNDS.y:
			room_matrix.get_element( i, j ).set_neighbor_of( room_matrix.get_element( (i+1)%ROOM_BOUNDS.x, j ) )
			room_matrix.get_element( i, j ).set_neighbor_of( room_matrix.get_element( i, (j+1)%ROOM_BOUNDS.y ) )
	
	# Step 2: print out all rooms in quadrant IV
	# Step 3: duplicate into quadrants I, II, III
	for i in ROOM_BOUNDS.x:
		for j in ROOM_BOUNDS.y:
			new_room = room_matrix.get_element( i, j )
			new_room.print_all_properties()
			new_room.set_position(Vector2i( new_room.get_position().x - (ROOM_BOUNDS.x*ROOM_SIZE.x),new_room.get_position().y) )
			new_room.print_all_properties()
			new_room.set_position( Vector2i(new_room.get_position().x, new_room.get_position().y-(ROOM_BOUNDS.y*ROOM_SIZE.y)) )
			new_room.print_all_properties()
			#new_room.set_position(Vector2i( new_room.get_position().x + (ROOM_BOUNDS.x*ROOM_SIZE.x),new_room.get_position().y) )
			#new_room.print_all_properties()
			#new_room.set_position( Vector2i(new_room.get_position().x, new_room.get_position().y+(ROOM_BOUNDS.y*ROOM_SIZE.y)) )
			# tagged out so center of map is more visible if the code was working, which it is not.
			
	# Step 4: set up silent teleporation if player walks beyond ROOM_BOUNDS/2 in any direction
	is_even_more_ready = true;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#if !is_even_more_ready:
	#	even_more_ready()
	
	pass
