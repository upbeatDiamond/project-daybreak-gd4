# Opens and closes Battles

extends Node

const BATTLE_GUI_PATH = "/root/SceneManager/InterfaceBattle/SubViewport/BattleGUI"
var current_battle : BattleSession = null
var battle_gui : BattleClientGUI

# Called when the node enters the scene tree for the first time.
func _ready():
	battle_gui = get_node(BATTLE_GUI_PATH) as BattleClientGUI
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
	GlobalRuntime._switch_io_state(GlobalRuntime.GameIOState.BATTLE)


func new_battle_dummy() -> BattleSession:
	
	var _fighter:Combatant # Oh yeah, calling it 'Battler' and 'Combatant' wasn't enough.
	var _moves:Array[BattleMove]
	
	var team_home = BattleTeam.new()
	var team_away = BattleTeam.new()
	
	_moves = [BattleMove.new("Tail Whip", 0), BattleMove.new("Sparks", 4, 2), 
				BattleMove.new("Headbutt", 5), BattleMove.new("Punch", 3)]
	_fighter = Combatant.new( battle_gui, team_home, 4, "Taurus" )
	_fighter.set_max_hp( 28 )
	_fighter.set_hp( _fighter.get_max_hp() )
	_fighter.set_max_fs( 12 )
	_fighter.set_fs( _fighter.get_max_fs() )
	_fighter.moves.append_array(_moves)
	team_away.battlers[BattleTeam.FieldPos.ACTIVE_LEFT] = _fighter
	
	_moves = [BattleMove.new("Sting", 3, 1), BattleMove.new("Paper Cut", 2),
				BattleMove.new("Sap Strength", 2, -2), BattleMove.new("Bite", 4, 1)]
	_fighter = Combatant.new( battle_gui, team_home, 1, "Scorpio" )
	_fighter.set_max_hp( 21 )
	_fighter.set_hp( _fighter.get_max_hp() )
	_fighter.set_max_fs( 16 )
	_fighter.set_fs( _fighter.get_max_fs() )
	_fighter.moves.append_array(_moves)
	team_away.battlers[BattleTeam.FieldPos.ACTIVE_MIDDLE] = _fighter
	
	
	_moves = [BattleMove.new("Growl", 0, -1), BattleMove.new("Chomp", 3, 1), 
				BattleMove.new("Water Surge", 5, 3), BattleMove.new("Hoof", 4)]
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
	
	_moves = [BattleMove.new("Crunch", 5), BattleMove.new("Slash", 9), 
				BattleMove.new("Tackle", 6), BattleMove.new("Howl", 0)]
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
	GlobalRuntime.scene_manager.mount_battle(battle)
	battle.battle_finished.connect(end_battle)
	mount_battle(battle)
	
	return battle


func end_battle( battle:BattleSession, winners:BattleTeam ):
	
	## TODO: adapt to work for more battles!
	if winners == battle.team_home:
		GlobalDatabase.save_keyval("battle_tutorial", "lose")
	else:
		GlobalDatabase.save_keyval("battle_tutorial", "win")
	battle.session_completed.emit()
	
