extends "res://battle/moves/moveeffect.gd"
# If I called this a 'swipe', that'd be false.


func execute_effect( user, targets : Array, traits : Dictionary ):
	
	for target in targets:
		var raw_damage = GlobalMove.calculate_raw_damage( traits["types"], user, target );
		
		if (raw_damage >= target.getHealth() ):
			raw_damage = target.getHealth() - 1;
		
		target.apply_damage( raw_damage )
	
	pass
