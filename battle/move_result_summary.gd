extends RefCounted
class_name MoveResultSummary
# Used because dictionaries are unreliable for debugging, as far as I am aware. "AFAIAA"?

var stat_changes : Array
var targets : Array[Combatant]

func _init():
	var i := GlobalMonster.BattleStats.size()
	while i > 0:
		stat_changes.append(0)
		i -= 1 
	pass

func get_targets() -> Array[Combatant]:
	return targets

func append_target( new_target ):
	targets.append(new_target)

func remove_target( old_target ):
	var index = targets.find( old_target )
	if index > -1:
		targets.remove_at( index )

func clear_targets():
	targets = []

func set_stat( stat_type:GlobalMonster.BattleStats, value:int ):
	stat_changes[stat_type] = value
	pass

func get_stat( stat_type:GlobalMonster.BattleStats ):
	return stat_changes[stat_type]
