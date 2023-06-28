extends RefCounted
class_name MoveResultSummary
# Used because dictionaries are unreliable for debugging, as far as I am aware. "AFAIAA"?

var stat_changes : Array
var target : Combatant

func _init():
	var i := GlobalMonster.BattleStats.size()
	while i > 0:
		stat_changes.append(0)
		i -= 1 
	pass

func get_target() -> Combatant:
	return target

func set_target( new_target ):
	target = new_target

func set_stat( stat_type:GlobalMonster.BattleStats, value:int ):
	stat_changes[stat_type] = value
	pass

func get_stat( stat_type:GlobalMonster.BattleStats ):
	return stat_changes[stat_type]
	pass
