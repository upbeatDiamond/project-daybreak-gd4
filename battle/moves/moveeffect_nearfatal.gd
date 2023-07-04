extends "res://battle/moves/moveeffect.gd"
# If I called this a 'swipe', that'd be false.


func calculate_effect( user, targets : Array, traits : Dictionary, current_effects : MoveResultSummary ):
	
	for target in targets:
		var raw_damage = GlobalMove.calculate_raw_damage( traits["types"], user, target );
		
		if (raw_damage >= target.getHealth() ):
			raw_damage = target.getHealth() - 1;
		
		#var delta = MoveResultSummary.new()
		current_effects.set_stat( GlobalMonster.BattleStats.HEALTH, raw_damage )
	
	pass
