extends Marker2D
class_name WarpAnchor

# Used as a form of unique ID within a given map
@export var anchor_name:String

# Used to tell which way an entity should face upon entry
@export var facing_direction:Vector2i

# Just a silly goofy funny lil thing to store. Should usually be (8, 8)
# Used to remind devs which of the 4 tiles this one actually signifies
@export var tile_px_offset:=Vector2i(8,8):
	set(_n):
		tile_px_offset=Vector2i(8,8)
	get:
		return tile_px_offset

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func get_warp_anchor_name() -> String:
	return anchor_name
