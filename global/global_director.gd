extends Node

var clyde : ClydeDialogue
var state_prior := GlobalRuntime.GameIOState.WORLD
var is_running_event := false

var key_values := {}
var registered_things := {}	# Stores actor ids, referenced by (key)name
var registered_names := {} 	# Stores displayed name, ref'd by keyname
var registered_alias := {}	# Stores actor pseudonyms

#var external_variables := {
	#"player_name": "Steve?"
#}

# spritesheet?
var iconsets : Dictionary
var prev_line_type := "line"
var next_line : Dictionary


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_clyde()
	# TODO: Store in global variables, so load only once per file (not each instance of Dialog)
	db_voices = load_file(voices_file)


func reset_clyde():
	clyde = ClydeDialogue.new()
	clyde.dialogue_folder = "res://screenplays/clyde"


func _load_screenplay(file_name: String, block:String="") -> void:
	clyde.load_dialogue(file_name, block)
	
	for connection in clyde.variable_changed.get_connections():
		clyde.variable_changed.disconnect(connection.callable)
	clyde.variable_changed.connect(_on_variable_changed)
	
	for connection in clyde.event_triggered.get_connections():
		clyde.event_triggered.disconnect(connection.callable)
	clyde.event_triggered.connect(_on_event_triggered)
	
	## Setup external variable proxies. This will allow the dialogue to
	## access external variables and update them.
	clyde.on_external_variable_fetch(_on_external_variable_fetch)
	clyde.on_external_variable_update(_on_external_variable_update)
	


func run_screenplay(file_name: String, block:String="") -> void:
	_load_screenplay(file_name, block)
	_start_current_screenplay()
	pass


func _start_current_screenplay():
	state_prior = GlobalRuntime._switch_io_state(GlobalRuntime.GameIOState.WORLD_DIALOG)
	GlobalRuntime.scene_manager.dialog_box.start_dialog( await get_next_line() )


func get_next_line() -> Dictionary:
	next_line = clyde.get_content()
	
	if next_line["type"] == "line" and next_line.has("speaker") \
	and next_line["speaker"] == "!do" and next_line.has("text"):
		await do_string(next_line["text"])
		return await get_next_line()
	
	if next_line.has("speaker"):
		if next_line["speaker"] == null:
			next_line["speaker"] = ""
	elif next_line["type"] == "options":
		next_line["speaker"] = ""
	if next_line.get("text") == null:
		next_line["text"] = ""
	print(next_line["type"], " ~!~ ", next_line.get("text"))
	
	if next_line["type"] == "line" and \
	( next_line.get("speaker") == null or next_line.get("speaker") == "" ) and \
	( next_line.get("text") == null or next_line.get("text") == "" ) :
		return await get_next_line()
	
	return next_line


func _continue_current_screenplay():
	
	pass


func choose_dialog_option(id:int):
	clyde.choose(id)
	pass


func _end_current_screenplay():
	print( GlobalRuntime.GameIOState.find_key(state_prior), ", Wowza!" )
	GlobalRuntime._switch_io_state( state_prior )


func _on_variable_changed(key:String, val:Variant, val_prev:Variant):
	print("Director says '", key, "' tried to change from ", val_prev, "to", val)
	pass


func _on_event_triggered(key: String):
	print("event: ", key)
	
	match key.strip_edges().to_lower():
		"shake":
			screen_shake.emit()
		_:
			pass
	pass


func _on_external_variable_update(key:String, value) -> void:
	set_key_value(key,value)


func _on_external_variable_fetch(key:String):
	return get_key_value(key)


# return the value for a key
func get_key_value( key:String ):
	
	match key:
		"pc_they":
			pass
		"pc_them":
			pass
		"pc_themself":
			pass
		"pc_theirs":
			pass
		"pc_their":
			pass
		"pc_they_f":
			pass
		"pc_them_f":
			pass
		"pc_themself_f":
			pass
		"pc_theirs_f":
			pass
		"pc_their_f":
			pass
		"pc_they_m":
			pass
		"pc_them_m":
			pass
		"pc_themself_m":
			pass
		"pc_theirs_m":
			pass
		"pc_their_m":
			pass
		_:
			pass
	
	if key_values.has(key):
		return key_values[key]
	return GlobalDatabase.load_keyval(key)


func set_key_value( key:String, value ):
	if str(value).strip_edges().is_valid_int():
		value = str(value).to_int()
	elif str(value).strip_edges().is_valid_float():
		value = str(value).to_float()
	key_values[key] = value
	GlobalDatabase.save_keyval(key, value)


"""
	Runs a string as an action command, as a Clyde hack.
"""
func do_string(do:String):
	do = str(do + " ").to_lower()
	var parameters = do.split(" ")
	var d = parameters[0]
	var async = false
	
	if d == "async":
		async = true
		parameters = parameters.slice(1) # Pop out front, discard
		d = parameters[0]
	else:
		is_running_event = true
	
	match d:
		"walk_at", "walk_pt": #navigate to anchor
			pass
		"walk_pos": #navigate to coordinate
			if async:
				ev_walk_pos(parameters[1], parameters[2], parameters[3])
			else:
				await ev_walk_pos(parameters[1], parameters[2], parameters[3])
		"battle":
			ev_battle()
			pass
	pass
	
	is_running_event = false


## Parameters:
## duration - length in seconds to wait for
func ev_wait( parameters ):
	if parameters.has("duration"):
		await get_tree().create_timer( parameters["duration"] ).timeout


## Parameters:
## duration - length in seconds to wait for
func ev_walk_pos( gp:String, x, y ):
	var walking_pieces = []
	
	for piece in get_tree().get_nodes_in_group("gamepiece"):
		if (piece as Gamepiece).tag == gp:
			piece.find_child("*ontrol*").target_position = Vector2(str(x).to_int(), str(y).to_int())
			piece.find_child("*ontrol*").set("nav_mode", 2)
			walking_pieces.append(piece)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	for piece in walking_pieces:
		if piece.is_moving or piece.was_moving:
			await piece.gamepiece_stopped_signal
	
	return walking_pieces


func ev_battle():
	var sess = BattleServer.new_battle_dummy();
	sess.start_battle();


func ev_async():
	pass


"""
Simple Global variables.
TODO: move data to GAME.data or somewhere more organized w/ execute and condition checking, since dialog specific

Info:
	Godot Open Dialogue System
	by Tina Qin (QueenChristina)
	https://github.com/QueenChristina/gd_dialog
	License: MIT.
	Please credit me if you use! Thank you! <3
"""

signal screen_shake

@export var voices_file = "res://dialog/data/Voices.json"

# database of all voices, as JSON
var db_voices
var END_DIALOG_ID = "end" # The dialog next_id that will end the dialog, reserved keyword.


# Loads a file as JSON, returns JSON
func load_file(file_name):
	var file #= FileAccess.new()
	if FileAccess.file_exists(file_name):
		file = FileAccess.open(file_name, FileAccess.READ)
		var test_json_conv = JSON.new()
		test_json_conv.parse(file.get_as_text())
		var file_content = test_json_conv.get_data()
		if file_content == null:
			print("Could not parse " + file_name + " as JSON." + \
			"Please check syntax is correct, and that file is not empty.")
		return file_content
	else:
		print("File Open Error: could not open file " + file_name)
	
	if file != null:
		file.close()


## Below is imported from QueenChristina's Dialogue, GameState

# Handles pausing, unpausing, and letting other nodes know the current
# state of the dialogue system.

# TODO: You have to implement how the game reacts to the pause/unpause signal
# yourself. Pause/unpause is emitted when dialogue starts/ends.
# To do so, connect the responding node to the signal, and implement
# function that happens when signal is recieved.

signal pause
signal unpause

var talking = false: get = get_state_talking, set = set_state_talking
var is_cutscene_playing = false: get = get_state_cutscene, set = set_state_cutscene


func set_state_talking(is_talking):
	talking = is_talking
	if is_talking:
		pause.emit()
	elif not is_paused():
		# This check is necessary in case, for example, talking and cutscene both occur asynch.
		unpause.emit()


func get_state_talking():
	return talking


func set_state_cutscene(_is_cutscene_playing):
	is_cutscene_playing = _is_cutscene_playing
	if _is_cutscene_playing:
		emit_signal("pause")
	elif not is_paused():
		emit_signal("unpause")


func get_state_cutscene():
	return is_cutscene_playing


# Returns whether game is paused. Manually setting how nodes react to this setting
# allows greater control than get_tree().paused = true
func is_paused():
	return is_cutscene_playing or talking
