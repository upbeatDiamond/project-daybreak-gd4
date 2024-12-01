# Controls one or more combattants; extended by Client which also displays information
extends Control
class_name BattleController

var previous_combatant : Combatant = null

func run_turn(battler:Combatant) -> BattleAction:
	print("My name is ", battler.nickname, "[control]")
	previous_combatant = battler
	return BattleAction.new(BattleAction.ActionType.PASS, battler)

#func poll_action(battler:Combatant) -> BattleAction:
	#
	#var battle_action_option : Array[BattleAction] = []
	#
	#for move in moves:
		#battle_action_option.append(BattleAction.new( BattleAction.ActionType.MOVE, self, move ))
	#
	#return team.get_leader().decide( self, battle_action_option )


"""
	Filter for reducing an array
	returns true to add the element to the filtered array (is valid)
"""
static func is_alive_combatant(thing) -> bool:
	if thing is Combatant and thing != null and thing.get_hp() > 0 and thing.get_fs() > 0 \
	and not thing.can_psych_up:
		return true
	return false #thing != null
