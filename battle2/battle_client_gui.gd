extends BattleClient
class_name BattleClientGUI

# For the sake of simple code, we will assume all battles are triple battles...
# ... and always feature two teams.
# left = player's left; distant_mon_sprite_left = distant team's left, display on right-hand side.
signal _turn_finished()
signal enable_buttons()

var local_team:BattleTeam;
var local_mon_left:Combatant;
var local_mon_middle:Combatant;
var local_mon_right:Combatant;
@onready var local_mon_sprite_left:TextureRect = get_node("MonAvatars/LocalMons/MonLocalLeft")
@onready var local_mon_sprite_middle:TextureRect = get_node("MonAvatars/LocalMons/MonLocalMiddle")
@onready var local_mon_sprite_right:TextureRect = get_node("MonAvatars/LocalMons/MonLocalRight")
@onready var local_mon_meter_left:BattleStatTracker = get_node("Trackers/LocalTrackers/StatTrackerFlipped/StatTracker")
@onready var local_mon_meter_middle:BattleStatTracker = get_node("Trackers/LocalTrackers/StatTrackerFlipped2/StatTracker")
@onready var local_mon_meter_right:BattleStatTracker = get_node("Trackers/LocalTrackers/StatTrackerFlipped3/StatTracker")

var distant_team:BattleTeam;
var distant_mon_left:Combatant;
var distant_mon_middle:Combatant;
var distant_mon_right:Combatant;
@onready var distant_mon_sprite_left:TextureRect = get_node("MonAvatars/DistantMons/MonDistantLeft")
@onready var distant_mon_sprite_middle:TextureRect = get_node("MonAvatars/DistantMons/MonDistantMiddle")
@onready var distant_mon_sprite_right:TextureRect = get_node("MonAvatars/DistantMons/MonDistantRight")
@onready var distant_mon_meter_left:BattleStatTracker = get_node("Trackers/DistantTrackers/StatTracker")
@onready var distant_mon_meter_middle:BattleStatTracker = get_node("Trackers/DistantTrackers/StatTracker2")
@onready var distant_mon_meter_right:BattleStatTracker = get_node("Trackers/DistantTrackers/StatTracker3")

@onready var bulletin_bg = find_child("BulletinBG")
@onready var bulletin_home = find_child("BulletinHome")
@onready var bulletin_home_line : RichTextLabel = bulletin_home.find_child("TextDisplay")
@onready var bulletin_move = find_child("BulletinMoves")
@onready var bulletin_move_1 = bulletin_move.find_child("Move1")
@onready var bulletin_move_2 = bulletin_move.find_child("Move2")
@onready var bulletin_move_3 = bulletin_move.find_child("Move3")
@onready var bulletin_move_4 = bulletin_move.find_child("Move4")
@onready var bulletin_team = find_child("BulletinTeam")
@onready var bulletin_bag = find_child("BulletinBag")
@onready var bulletin_txt = find_child("BulletinText")
@onready var bulletin_txt_line : RichTextLabel = bulletin_txt.find_child("TextDisplay")
@onready var bulletin_pieces:Array=[bulletin_bg, bulletin_home, bulletin_move, \
		bulletin_team, bulletin_bag, bulletin_txt]

## Deprecated variable name
var is_team_1:bool=true ## Terminology is confused; team1/team0 != team1/team2
var battle:BattleSession
var queued_action : BattleAction = BattleAction.new(BattleAction.ActionType.PASS, null)
var current_combatant:Combatant


func _init():
	pass


func _ready():
	_update_distant_team()
	_update_local_team()
	link_buttons()


func _input(_ie:InputEvent) -> void:
	#TODO make input select things
	pass


func _sync_to_battle(_battle:BattleSession):
	battle = _battle
	distant_mon_left = battle.team_away_left
	distant_mon_middle = battle.team_away_center
	distant_mon_right = battle.team_away_right
	local_mon_left = battle.team_home_right
	local_mon_middle = battle.team_home_center
	local_mon_right = battle.team_home_left
	
	_update_local_team()
	_update_distant_team()
	
	#TODO: write code to clear out previous battle, or prove it's better to toss and create anew


func _update_distant_team():
	var p
	
	# Guard clause
	if(battle == null):
		return
	if(is_team_1):
		if(battle.team_away == null):
			return
	else:
		if(battle.team_home == null):
			return
	
	distant_team = battle.team_home
	p = distant_team.battlers[BattleTeam.FieldPos.ACTIVE_LEFT]
	if (p != null):
		distant_mon_sprite_right.texture = p.get_front_sprite()
		distant_mon_meter_right.link_combatant(p)
		distant_mon_right = p
		distant_mon_sprite_right.visible = true
		distant_mon_meter_right.visible = true
	else:
		distant_mon_sprite_right.visible = false
		distant_mon_meter_right.visible = false
	
	p = distant_team.battlers[BattleTeam.FieldPos.ACTIVE_MIDDLE]
	if (p != null):
		distant_mon_sprite_middle.texture = p.get_front_sprite()
		distant_mon_meter_middle.link_combatant(p)
		distant_mon_left = p
		distant_mon_sprite_middle.visible = true
		distant_mon_meter_middle.visible = true
	else:
		distant_mon_sprite_middle.visible = false
		distant_mon_meter_middle.visible = false
		
	p = distant_team.battlers[BattleTeam.FieldPos.ACTIVE_RIGHT]
	if (p != null):
		distant_mon_sprite_left.texture = p.get_front_sprite()
		distant_mon_meter_left.link_combatant(p)
		distant_mon_left = p
		distant_mon_sprite_left.visible = true
		distant_mon_meter_left.visible = true
	else:
		distant_mon_sprite_left.visible = false
		distant_mon_meter_left.visible = false
	
	pass


func _update_local_team():
	var p
	
	# Guard clause
	if(battle == null):
		return
	if(is_team_1):
		if(battle.team_away == null):
			return
	else:
		if(battle.team_home == null):
			return
	
	local_team = battle.team_away
	p = local_team.battlers[BattleTeam.FieldPos.ACTIVE_RIGHT]
	if (p != null):
		var _size = local_mon_sprite_right.size
		local_mon_sprite_right.texture = p.get_back_sprite()
		local_mon_sprite_right.size = _size
		local_mon_meter_right.link_combatant(p)
		local_mon_right = p
		local_mon_sprite_right.visible = true
		local_mon_meter_right.visible = true
	else:
		local_mon_sprite_right.visible = false
		local_mon_meter_right.visible = false
		
	p = local_team.battlers[BattleTeam.FieldPos.ACTIVE_MIDDLE]
	if (p != null):
		local_mon_sprite_middle.texture = p.get_back_sprite()#.resize(local_mon_sprite_middle.size)
		local_mon_meter_middle.link_combatant(p)
		local_mon_left = p
		local_mon_sprite_middle.visible = true
		local_mon_meter_middle.visible = true
	else:
		local_mon_sprite_middle.visible = false
		local_mon_meter_middle.visible = false
		
	p = local_team.battlers[BattleTeam.FieldPos.ACTIVE_LEFT]
	if (p != null):
		local_mon_sprite_left.texture = p.get_back_sprite()#.resize(local_mon_sprite_left.size)
		local_mon_meter_left.link_combatant(p)
		local_mon_left = p
		local_mon_sprite_left.visible = true
		local_mon_meter_left.visible = true
	else:
		local_mon_sprite_left.visible = false
		local_mon_meter_left.visible = false
	
	pass


func link_buttons():
	var bp = bulletin_pieces.duplicate()
	for piece in bp:
		if (piece is Node):
			bp.append_array( (piece as Node).get_children() ) #enable_buttons(gui:BattleInterface)
			if ((piece as Node).has_method("_link_to_gui")):
				piece._link_to_gui(self)
	pass


func run_turn(battler:Combatant) -> BattleAction:
	
	# Set current focus to the current combatant
	current_combatant = battler
	print("My name is ", battler.nickname, "[gui]")
	bulletin_home_line.text = str("What will ", battler.nickname, " do?")
	
	# Change move list to correspond with battler's list of moves
	# Move list should always be 4 elements long.
	# In case it's not 4 elements wrong, we can use a safety check
	var _move = null
	
	for x in range(4):
		_move = null
		var move_btn = self.get(str( "bulletin_move_", (x + 1) )).find_child("MoveName")
		
		if(battler.moves.size() > x):
			_move = battler.moves[x]
		if(_move != null):
			#self.get(str( "bulletin_move_", (x + 1) )).find_child("MoveName").
			move_btn.text = _move.mname
			move_btn.visible = true
		else:
			#var move_btn = self.get(str( "bulletin_move_", (x + 1) )).find_child("MoveName")
			move_btn.text = "0"
			move_btn.visible = false
	
	## We must switch to HOME to enable player to press buttons.
	switch_ui_mode(IOMode.HOME)
	
	## After waiting for a button response, the turn can end.
	## When the turn ends, we can blank out the screen for 0.1 seconds to signify a switch
	## It may be ideal to replace this blanking with an animation later on.
	await _turn_finished
	print("~turn finished~")
	switch_ui_mode(IOMode.BLANK)
	await get_tree().create_timer(0.1).timeout
	
	return queued_action


func switch_ui_mode(_mode:IOMode):
	ui_mode = _mode
	
	for bull in bulletin_pieces:
		bull.visible=false
	
	match ui_mode:
		IOMode.TEXT:
			bulletin_bg.visible = true
			bulletin_txt.visible = true
		IOMode.TEXT_CONTINUE:
			## TODO: Continue to next block of text
			var txt = _get_next_summary()
			if txt == null:
				bulletin_txt_line.text = "no text to display :3"
				summaries_read.emit()
				return switch_ui_mode(IOMode.BLANK)
			bulletin_txt_line.text = txt
			switch_ui_mode(IOMode.TEXT)
		IOMode.BLANK:
			if summaries.size() <= 0:
				summaries_read.emit()
			pass
		IOMode.MOVE:
			bulletin_bg.visible = true
			bulletin_move.visible = true
		IOMode.BAG:
			bulletin_bg.visible = true
			bulletin_bag.visible = true
		IOMode.TEAM:
			bulletin_bg.visible = true
			bulletin_team.visible = true
		_: # IOMode.HOME:
			bulletin_bg.visible = true
			bulletin_home.visible = true
			enable_buttons.emit()
	
	pass


func submit_action_info(_act_type:BattleAction.ActionType, _act_index:int, _act_target=null):
	print(_act_type, " ^ ", _act_index, "; BCG submit_action_info")
	queued_action = BattleAction.new(_act_type, current_combatant)
	
	if(_act_type == BattleAction.ActionType.MOVE):
		queued_action.action_core = current_combatant.moves[_act_index]
	
	## TODO: replace after demo!
	queued_action.targets = battle.team_home.battlers.slice(0,3)
	
	_turn_finished.emit()
