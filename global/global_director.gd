extends Node

var clyde : ClydeDialogue
var unpaused_prior := true


var key_values := {}
var registered_things := {}	# Stores actor ids, referenced by (key)name
var registered_names := {} 	# Stores displayed name, ref'd by keyname
var registered_alias := {}	# Stores actor pseudonyms

var external_variables := {
	"player_name": "Steve?"
}

# spritesheet?
var iconsets : Dictionary
var prev_line_type := "line"
var next_line : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_clyde()
	# TODO: Store in global variables, so load only once per file (not each instance of Dialog)
	#db_dialog = LoadFile(dialog_file) #GlobalDialog.db_dialog
	db_voices = LoadFile(voices_file)
	pass # Replace with function body.


func reset_clyde():
	clyde = ClydeDialogue.new()
	
	clyde.dialogue_folder = "res://screenplays/clyde"
	
	#clyde.load_resource(resource, block)
	
	# Call get content to return the next dialogue line
	#clyde.get_content()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _load_screenplay(file_name: String, block:String="") -> void:
	await clyde.load_dialogue(file_name, block)
	
	clyde.variable_changed.connect(_on_variable_changed)
	clyde.event_triggered.connect(_on_event_triggered)
	
	# setup external variable proxies. This will allow the dialogue to
	# access external variables and update them
	clyde.on_external_variable_fetch(_on_external_variable_fetch)
	clyde.on_external_variable_update(_on_external_variable_update)
	


func run_screenplay(file_name: String, block:String="") -> void:
	_load_screenplay(file_name, block)
	_start_current_screenplay()
	#while clyde.get_content() != null:
	#	GlobalRuntime.scene_manager.dialog_box.
	pass

func _start_current_screenplay():
	unpaused_prior = GlobalRuntime.gameworld_input_enabled(false)
	GlobalRuntime.scene_manager.dialog_box.start_dialog( get_next_line() )

func get_next_line() -> Dictionary:
	next_line = clyde.get_content()
	return next_line

func _continue_current_screenplay():
	
	pass

func choose_dialog_option(id:int):
	clyde.choose(id)
	pass

func _end_current_screenplay():
	GlobalRuntime.gameworld_input_enabled( unpaused_prior )


func _on_variable_changed(key:String, val:Variant, val_prev:Variant):
	pass


func _on_event_triggered(key: String):
	print("event: ", key)
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
	#return null


func set_key_value( key:String, value ):
	key_values[key] = value
	GlobalDatabase.save_keyval(key, value)


# Parameters:
# duration - length in seconds to wait for
func ev_wait( parameters ):
	if parameters.has("duration"):
		await get_tree().create_timer( parameters["duration"] ).timeout
		

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

#extends Node

signal screen_shake

#@export var dialog_file = "res://dialog/data/Dialogue.json"
@export var voices_file = "res://dialog/data/Voices.json"

# database of all dialogues and voices, as JSON
#var db_dialog 
var db_voices
var END_DIALOG_ID = "end" # The dialog next_id that will end the dialog, reserved keyword.
var data = {} # TODO: keep data here, but move actionHandler # In game global data, used for conditionals in dialog

var player_name = "Bobby" # TODO: move to Player stats

## Called when the node enters the scene tree for the first time.
#func _ready():



# Whether a condition (string) is met.	
# condition must be in format of: source_of_variable variable_name conditional_operator value optional_amount
func is_condition_met(condition : String):
	var cond_parsed = condition.split(" ")
	# Error checking
	var num_args = cond_parsed.size()
	if num_args < 4:
		print("WARNING: condition of " + condition + " not set appropriately. Too few args.")
	
	# Check if condition met
	var var_source = cond_parsed[0].to_lower()	# to_lower to check conditionals
	var variable = cond_parsed[1]				# Not to_lower to preserve original intention
	var operator = cond_parsed[2].to_lower()
	var value = cond_parsed[3]
	if var_source == "data":
		# Use variable keys in GlobalDialog.data dictionary
		if not data.has(variable):
			print("WARNING: data key of " + variable + "not set. " + \
				"Attempting to compare with defaulted assumed value of false.")
			return compare("false", operator, value)
		else:
			return compare(data[variable], operator, value)
	# TODO: implement your own ways of interpreting/evaluating conditions here where cond_parsed
	# is the space-delineated strings that describe a condition
	# The condition should ultimately evaluate to true or false
	else:
		print("WARNING: Unknown condition of source "+ var_source + ". Defaulting to false.")
	print("WARNING: Unknown condition "+ condition + ". Defaulting to false.")
	return false

# Compares two values with string comparision operator. If operator is not "equal", then 
# values must be castable to integer. Assume types and operators are appropriate.
# TODO: support for floats, beware of floating-point precision
func compare(thing1, operator : String, thing2):
#	print("Comparing if " + thing1 + " is " + operator + thing2)
	if operator == "equal" or operator == "equals" or operator == "is" or operator == "==":
		# May be string or integer values.
		return thing1 == thing2
	elif operator == "not_equal" or operator == "not" or operator == "!=":
		return thing1 != thing2
	elif operator == "less" or operator == "<":
		# Must be castable to integer.
		return int(thing1) < int(thing2)
	elif operator == "greater" or operator == ">":
		return int(thing1) > int(thing2)
	print("WARNING: Couldn't find condition operator " + operator)
	return false

# Loads a file as JSON, returns JSON
func LoadFile(file_name):
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
		emit_signal("pause")
	elif not is_paused():
		# This check is necessary in case, for example, talking and cutscene both occur asynch.
		emit_signal("unpause")
	
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
	return talking or is_cutscene_playing

#func get_next_line():
	#pass
