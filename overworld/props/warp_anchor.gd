##@tool
extends Marker2D
class_name WarpAnchor

# Used as a form of unique ID within a given map
@export var anchor_name:String: 
	set(val):
		if Engine.is_editor_hint():
			GlobalDatabase.erase_anchor_coord(map, anchor_name)
			anchor_name = val
			_save_self_to_db()

# Used to tell which way an entity should face upon entry
@export var facing_direction:Vector2i

# Just a silly goofy funny lil thing to store. Should usually be (8, 8)
# Used to remind devs which of the 4 tiles this one actually signifies
@export var tile_px_offset:=Vector2i(8,8):
	set(_n):
		tile_px_offset=Vector2i(8,8)
	get:
		return tile_px_offset

var has_saved_self := false
var map := LevelMap.MapIndex.INVALID_INDEX

# Called when the node enters the scene tree for the first time.
func _ready():
	var parent = get_parent()
	while parent != null:
		if parent is LevelMap:
			map = parent.map_index
			break
		parent = get_parent()
	if parent == null and map == LevelMap.MapIndex.INVALID_INDEX:
		assert(false, "WarpAnchor needs to be inside a LevelMap!")
	
	if Engine.is_editor_hint():
		_save_self_to_db()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not has_saved_self and not Engine.is_editor_hint():
		_save_self_to_db()
	pass


func _save_self_to_db():
	GlobalDatabase.save_anchor_coord( map, anchor_name, global_position )
	has_saved_self = true


func get_warp_anchor_name() -> String:
	return anchor_name
