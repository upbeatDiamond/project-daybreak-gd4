extends Node
## This class is dedicated to tools formerly belonging to G.Runtime/G.State, as well as
## any other functions that may be called by any class at nearly any time, without being
## a part of the world itself.

const DEFAULT_TILE_SIZE := 16
const DEFAULT_TILE_OFFSET := Vector2.ONE * floor(  (GlobalTools.DEFAULT_TILE_SIZE + 1)/2.0 )
const DEFAULT_TILE_OFFSET_INT := Vector2i( DEFAULT_TILE_OFFSET )
const CAMERA_TWEEN_DURATION := 1.0

# Cleans up all children of a node, and their children, and their children, etc
func clean_up_descent( target_node : Node ):
	var mark_for_deletion : Array = target_node.get_children()
	var current_mark
	
	while mark_for_deletion.size() > 0:
		current_mark = mark_for_deletion.pop_front()
		mark_for_deletion.append_array( current_mark.get_children() )
		
		if target_node.get_parent() != null: 
			target_node.get_parent().remove_child( target_node )
			
		if current_mark.has_method("clean_up"): 
			current_mark.clean_up()
			
		current_mark.queue_free()


# Queues deletion of a node and all of its child nodes
# This is intended to slow down inevitable memory leakage
# Maybe the arrays mess this up, but it also helps clean up scene transitions sometimes
# Might be redudant? Depends on how Godot implements queue_free
func clean_up_node_descent( target_node : Node ):
	if target_node.has_method("clean_up"):
		target_node.clean_up()
	clean_up_descent(target_node)
	target_node.queue_free()


func snap_to_grid( pos ) -> Vector2:
	return snap_to_grid_center_f( pos )


func snap_to_grid_center_f( pos ) -> Vector2:
	return snap_to_grid_corner_f( pos ) + DEFAULT_TILE_OFFSET


func snap_to_grid_center_i( pos ) -> Vector2i:
	return snap_to_grid_corner_i( pos ) + DEFAULT_TILE_OFFSET_INT


func snap_to_grid_corner_f( pos ) -> Vector2:
	pos = Vector2(pos.x - DEFAULT_TILE_OFFSET.x, pos.y - DEFAULT_TILE_OFFSET.y)
	return pos.snapped(Vector2.ONE * GlobalTools.DEFAULT_TILE_SIZE)


func snap_to_grid_corner_i( pos ) -> Vector2i:
	pos = Vector2i(pos.x - DEFAULT_TILE_OFFSET.x, pos.y - DEFAULT_TILE_OFFSET.y)
	pos = pos.snapped(Vector2i.ONE * GlobalTools.DEFAULT_TILE_SIZE) #+ DEFAULT_TILE_OFFSET_INT
	return pos

func multiply_string( _text:String, count:int, _separator:="" ) -> String:
	var ret = ""
	if count > 0:
		ret = _text
		count -= 1
		while count > 0:
			ret = str(ret, _separator, _text)
			count -= 1
	return ret

#region Bit Manip

func get_flag_bit(bitfield:int, flag_index:int):
	return get_bitflag(bitfield, flag_index);

func get_bitflag(bitfield:int, flag_index:int):
	return compare_bitfield_flag(bitfield, flag_index);

# Needs testing, depricated name
func compare_bitfield_flag( bitfield:int, flag_index:int ):
	return (bitfield >> flag_index) & 0x1

# Needs testing
func compare_bitfield_mask( bitfield:int, mask:int ):
	return bitfield & mask

func set_bitflag(bitfield:int, flag_index:int, value:int):
	return update_bitfield_flag( bitfield, flag_index, value )

func invert_bitfield( bitfield:int ):
	return 0 - bitfield - 1		# Some weird Two's Complement stuff, not yet tested

# Needs testing, depricated name
func update_bitfield_flag( bitfield:int, flag_index:int, value:int ):
	var filter = 1						# Sets the variable to 0x00...01
	value = value << flag_index			# Shifts the value into position
	filter = ~(filter << flag_index)	# Shifts the 1 into position, ...
										# ...then flips everything so that that bit is excluded.
	return (bitfield & filter) + value	# Fills in excluded position with new bit value

#endregion
