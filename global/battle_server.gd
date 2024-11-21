# Opens and closes Battles

extends Node

var current_battle : BattleSession = null
var battle_gui : BattleClientGUI

# Called when the node enters the scene tree for the first time.
func _ready():
	battle_gui = get_node("/root/TestBuddy/BattleGUI") as BattleClientGUI
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	pass


func new_battle():
	pass


func mount_battle(battle):
	battle_gui._sync_to_battle(battle)
	add_child(battle)
	current_battle = battle
	print("Server adopted a battle")


func new_battle_dummy() -> BattleSession:
	
	var _fighter:Combatant # Oh yeah, calling it 'Battler' and 'Combatant' wasn't enough.
	var _moves:Array[BattleMove]
	
	var team_home = BattleTeam.new()
	var team_away = BattleTeam.new()
	
	_moves = [BattleMove.new("Sparks", 2, 2), BattleMove.new("Tail Whip", 0), 
				BattleMove.new("Headbutt", 5), BattleMove.new("Punch", 3)]
	_fighter = Combatant.new( battle_gui, team_home, 4, "Taurus" )
	_fighter.set_max_hp( 28 )
	_fighter.set_hp( _fighter.get_max_hp() )
	_fighter.set_max_fs( 12 )
	_fighter.set_fs( _fighter.get_max_fs() )
	_fighter.moves.append_array(_moves)
	team_away.battlers[BattleTeam.FieldPos.ACTIVE_LEFT] = _fighter
	BattleTeam.FieldPos.ACTIVE_LEFT
	
	_moves = [BattleMove.new("Bite", 3, 1), BattleMove.new("Sting", 4, 1), 
				BattleMove.new("Sap Strength", 2, -2), BattleMove.new("Paper Cut", 2)]
	_fighter = Combatant.new( battle_gui, team_home, 1, "Scorpio" )
	_fighter.set_max_hp( 21 )
	_fighter.set_hp( _fighter.get_max_hp() )
	_fighter.set_max_fs( 16 )
	_fighter.set_fs( _fighter.get_max_fs() )
	_fighter.moves.append_array(_moves)
	team_away.battlers[BattleTeam.FieldPos.ACTIVE_MIDDLE] = _fighter
	
	
	_moves = [BattleMove.new("Water Surge", 4, 3), BattleMove.new("Chomp", 3, 1), 
				BattleMove.new("Growl", 0, -1), BattleMove.new("Hoof", 3)]
	_fighter = Combatant.new( battle_gui, team_home, 7, "Capricorn" )
	_fighter.set_max_hp( 23 )
	_fighter.set_hp( _fighter.get_max_hp() )
	_fighter.set_max_fs( 22 )
	_fighter.set_fs( _fighter.get_max_fs() )
	_fighter.moves.append_array(_moves)
	team_away.battlers[BattleTeam.FieldPos.ACTIVE_RIGHT] = _fighter
	
	

	#_moves = [BattleMove.new("Crystal Heal"), BattleMove.new("Dracon Breath"), 
				#BattleMove.new("Roar"), BattleMove.new("Cascade")]
	#_fighter = Combatant.new( gui, team_home, "Jean" )
	#_fighter.moves.append_array(_moves)
	#team_away.battlers.append(_fighter)
	
	_moves = [BattleMove.new("Crunch", 6), BattleMove.new("Slash", 10), 
				BattleMove.new("Tackle", 7), BattleMove.new("Howl", 0)]
	_fighter = Combatant.new( battle_gui, team_home, 229, "Cerberus" )
	_fighter.set_max_hp( 85 )
	_fighter.set_hp( _fighter.get_max_hp() )
	_fighter.set_max_fs( 121 )
	_fighter.set_fs( _fighter.get_max_fs() )
	_fighter.controller = BattleControllerNPC.new()
	_fighter.moves.append_array(_moves)
	team_home.battlers[BattleTeam.FieldPos.ACTIVE_MIDDLE] = _fighter
	
	#_moves = [BattleMove.new("Heavy Slam"), BattleMove.new("Sonic Cannon"), 
				#BattleMove.new("Roar"), BattleMove.new("Crawlspace")]
	#_fighter = Combatant.new( gui, team_home, "William" )
	#_fighter.moves.append_array(_moves)
	#team_away.battlers.append(_fighter)
	
	var battle = BattleSession.new(team_home, team_away)
	mount_battle(battle)
	
	return battle
