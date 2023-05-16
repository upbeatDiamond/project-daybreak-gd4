extends Node
# I called it Manip because Manip is fun to say. Short for Manipulation. Manip. Hehe.

# randomize() is called here because this class relates to bits, and that's what RNG is used for?
# what other 'global' class would fit better?
func _init():
	randomize()

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

func invert( bitfield:int ):
	return 0 - bitfield - 1		# Some weird Two's Complement stuff, not yet tested

# Needs testing, depricated name
func update_bitfield_flag( bitfield:int, flag_index:int, value:int ):
	var filter = 1						# Sets the variable to 0x00...01
	value = value << flag_index			# Shifts the value into position
	filter = ~(filter << flag_index)	# Shifts the 1 into position, ...
										# ...then flips everything so that that bit is excluded.
	return (bitfield & filter) + value	# Fills in excluded position with new bit value
