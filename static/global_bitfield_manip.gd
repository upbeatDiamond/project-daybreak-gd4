extends Node
# I called it Manip because Manip is fun to say. Short for Manipulation. Manip. Hehe.

func compare_bitfield_flag( bitfield, flag_index ):
		return (bitfield >> flag_index) & 01

func compare_bitfield_mask( bitfield, mask ):
		return bitfield & mask
