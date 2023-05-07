extends Node
# I called it Manip because Manip is fun to say. Short for Manipulation. Manip. Hehe.

# randomize() is called here because this class relates to bits, and that's what RNG is used for?
# what other 'global' class would fit better?
func _init():
	randomize()

# Needs testing
func compare_bitfield_flag( bitfield, flag_index ):
	return (bitfield >> flag_index) & 01

# Needs testing
func compare_bitfield_mask( bitfield, mask ):
	return bitfield & mask

# Needs testing
func update_bitfield_flag( bitfield, flag_index, value ):
	var filter = 1						# Sets the variable to 0x00...01
	value << flag_index					# Shifts the value into position
	filter = ~(filter << flag_index)	# Shifts the 1 into position, ...
										# ...then flips everything so that that bit is excluded.
	return (bitfield & filter) + value	# Fills in excluded position with new bit value
