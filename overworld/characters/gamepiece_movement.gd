extends Object
class_name Movement

# enum for facing/moving towards direction
enum Direction{
	NEUTRAL = 0,
	NORTH = 1,
	EAST,
	SOUTH,
	WEST,
}

# enum for how fast you're moving / on what terrain
#var Method := Gamepiece.TraversalMode

var direction:Direction
var method:Gamepiece.TraversalMode

func _init( vector:=Vector2i(0,0), _method:=Gamepiece.TraversalMode.WALKING ):
	method = _method
	
	if abs(vector.x) == abs(vector.y):
		direction = Direction.NEUTRAL
	elif abs(vector.x) > abs(vector.y):
		if int(vector.x + 0.5) >= 1:
			direction = Direction.SOUTH
		else:
			direction = Direction.NORTH
	else:
		if int(vector.y + 0.5) >= 1:
			direction = Direction.EAST
		else:
			direction = Direction.WEST
	pass

func to_facing_vector2i() -> Vector2i:
	var vector_export := Vector2i(0,0)
	
	vector_export.x = int(direction == Direction.SOUTH) - int(direction == Direction.NORTH)
	vector_export.y = int(direction == Direction.EAST) - int(direction == Direction.WEST)
	
	return vector_export
	pass

func to_facing_vector2f() -> Vector2:
	var vec = to_facing_vector2i()
	return Vector2( vec.x, vec.y )
	pass

func to_cell_vector2i() -> Vector2i:
	if method == Gamepiece.TraversalMode.STANDING:
		return Vector2i(0,0)

	return to_facing_vector2i()
	pass

func to_cell_vector2f() -> Vector2:
	var vec = to_cell_vector2i()
	return Vector2( vec.x, vec.y )
