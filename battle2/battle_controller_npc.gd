class_name BattleControllerNPC
extends BattleController


func run_turn(battler:Combatant) -> BattleAction:
	print("My name is ", battler.nickname, "[client/npc]")
	
	var move : BattleMove = battler.moves.filter(func(x): return x != null).pick_random()
	var target = null
	var battle = BattleServer.current_battle
	
	if battler in battle.team_home.battlers:
		target = battle.team_away.battlers.slice(0,3).filter(is_alive_combatant).pick_random()
		pass
	elif battler in battle.team_away.battlers:
		target = battle.team_home.battlers.slice(0,3).filter(is_alive_combatant).pick_random()
		pass
	
	if move == null:
		move = BattleMove.new("Struggle")
	
	print("I, [npc], selected ", move.mname, " for ", target)
	
	return BattleAction.new(BattleAction.ActionType.MOVE, battler, move, [target])
