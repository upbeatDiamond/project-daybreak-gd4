# replaces Battle, represents individual matches
extends Node
class_name BattleSession


## For when a winner is decided, not when the session is done running.
signal battle_finished( battle:BattleSession, winners:BattleTeam )

## For when the session is done running; should be listened to by scene manager
signal session_completed( winner:BattleTeam )

var team_home:BattleTeam # Represents NPCs in singleplayer, or the host in multiplayer
var team_away:BattleTeam # Represents the player, who is often "just visiting".
var battler_queue:Array[Combatant]
var round_counter := 0;

var team_home_left: Combatant
var team_home_center: Combatant
var team_home_right: Combatant

var team_away_left: Combatant
var team_away_center: Combatant
var team_away_right: Combatant

var has_begun:bool=false
var can_run_turn:bool=false

var queued_actions:Array[BattleAction]=[]

var mode := Mode.BATTLER_POLL
enum Mode{
	BATTLER_POLL,
	ACTION
}

func _init(_team_home:BattleTeam, _team_away:BattleTeam):
	team_home = _team_home
	team_away = _team_away


# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if(has_begun and can_run_turn and round_counter < 99):
		run_turn()
	pass


func start_battle():
	has_begun = true
	can_run_turn = true
	round_counter = 0
	set_process(true)


func run_turn():
	# lock the loop so it has to pause and wait
	can_run_turn = false
	
	match mode:
		Mode.ACTION:
			if(queued_actions.size() <= 0):
				mode = Mode.BATTLER_POLL
			else:
				await _run_action( queued_actions.pop_front() )
		_: #BATTLER_POLL
			var next_battler = battler_queue.pop_back()
			
			if(next_battler == null):
				mode = Mode.ACTION
				_next_round()
				print("round ", round_counter, " queuing has concluded.")
				round_counter += 1
			else:
				queued_actions.append( await next_battler.run_turn() )
			
			## Until we find another battler who is 'alive' (not fainted), keep searching.
			## Do not ask a fainted monster for their next move. They're fainted. Unconcious.
	
	can_run_turn = true
	pass


func _run_action(action:BattleAction):
	action.validate_action_type()
	
	if action.act_type == BattleAction.ActionType.MOVE:
		return await _run_move(action)
	else:
		print(action.act_type, ", idk how to run_action")


func _run_move(action:BattleAction):
	var summary = ""
	
	action.user.set_fs( action.user.get_fs() - action.action_core.energy_cost )
	await _post_summary(str(action.user, " used ", action.action_core.mname, "!") )
	
	if action.targets == null:
		action.targets = []
	while action.targets.has(null):
		action.targets.erase(null)
	#action.targets.erase(null)
	
	## Array to string, with brackets removed
	summary = str(action.targets).lstrip("[").rstrip("]")
	summary = str(summary, " took ", action.action_core.damage, \
	" damage from ", action.user, "'s ", action.action_core, "!"  )
	await _post_summary(summary)
	
	for target in action.targets:
		target.apply_health_change( -action.action_core.damage )
		print('target ', target, " has ", target.get_hp(), " hp remaining")
		if not BattleController.is_alive_combatant(target):
			if team_away.battlers.has(target):
				battle_finished.emit( self, team_home )
			elif team_home.battlers.has(target):
				battle_finished.emit( self, team_away )
			else:
				battle_finished.emit( self, null )
			
			await _post_summary(str( target, " has fainted!" ))
			## ^ This line causes issues somehow. I want to rewrite this code again.
	
	battler_queue = battler_queue.filter(BattleController.is_alive_combatant)
	print(battler_queue, " remain")
	pass


func _await_summaries_read():
	
	var clients = get_clients()
	
	## Await the blocks of text being read. 
	for client in clients:
		if client.summaries.size() > 0:
			await client.summaries_read
	
	return


func _post_summary(summary:String):
	var clients = get_clients()
	
	# Have each client print the next block of text
	for client in clients:
		client.append_summary(summary)
		if client.ui_mode not in [BattleClient.IOMode.TEXT, BattleClient.IOMode.TEXT_CONTINUE]:
			(client as BattleClient).switch_ui_mode(BattleClient.IOMode.TEXT_CONTINUE)
	print("POSTED: ", summary)
	
	await _await_summaries_read()


func get_clients() -> Array:
	var clients = []
	
	for b in get_battlers():
		# If we haven't seen this client yet, and it is a client, add to list.
		# Avoids duplication of calling 'switch to TEXT_CONTINUE'
		if b.controller is BattleClient and not( b.controller in clients ):
				clients.append(b.controller)
	
	return clients


func get_battlers() -> Array:
	var batts = []
	for b in team_home.battlers:
		if b:
			batts.append(b)
	
	for b in team_away.battlers:
		if b:
			batts.append(b)
	return batts


func _next_round():
	var sub_queue_home = []
	for b in team_home.battlers:
		if b:
			sub_queue_home.append(b)
	
	var sub_queue_away = []
	for b in team_away.battlers:
		if b:
			sub_queue_away.append(b)
	
	sub_queue_away = sub_queue_away.filter(BattleController.is_alive_combatant)
	sub_queue_home = sub_queue_home.filter(BattleController.is_alive_combatant)
	
	if sub_queue_away.size() <= 0:
		if sub_queue_home.size() <= 0:
			_post_summary("No contest!")
			battle_finished.emit(null)
		else:
			_post_summary(str(team_away, " is out of fighters!") )
			_post_summary(str(team_home, " wins!") )
			battle_finished.emit(team_home)
	elif sub_queue_home.size() <= 0:
		battle_finished.emit(team_away)
		_post_summary(str(team_home, " is out of fighters!") )
		_post_summary(str(team_away, " wins!") )
		session_completed.emit()
	else:
		battler_queue.append_array(sub_queue_away)
		battler_queue.append_array(sub_queue_home)
	
	# Sort battlers, so there's both sense and balance to their ordering
	battler_queue.sort_custom( _sort_battlers )
	print("battler queue: ", battler_queue)


# sorts slowest to fastest, so the fastest can be pulled off efficiently (less shifting)
func _sort_battlers(a:Combatant, b:Combatant) -> bool:
	if (a.get_speed() > b.get_speed()):
		return true
	return false
