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

extends Node

signal screen_shake

@export var dialog_file = "res://dialog/data/Dialogue.json"
@export var voices_file = "res://dialog/data/Voices.json"

# database of all dialogues and voices, as JSON
var db_dialog 
var db_voices
var END_DIALOG_ID = "end" # The dialog next_id that will end the dialog, reserved keyword.
var data = {} # TODO: keep data here, but move actionHandler # In game global data, used for conditionals in dialog

var player_name = "Bobby" # TODO: move to Player stats

# Called when the node enters the scene tree for the first time.
func _ready():
	# TODO: Store in global variables, so load only once per file (not each instance of Dialog)
	db_dialog = LoadFile(dialog_file) #GlobalDialog.db_dialog
	db_voices = LoadFile(voices_file)
	
# TODO: validate database. Debug script that validates db_dialog and db_voices when loaded. Then, remove 
# in-script warnings.

# Executes an action, currently supports:
# - "emit_signal args". Emits a signal (TODO)
# - "play_anim animationName". Emits a signal to play animation by name of animationName.
# - "set variable value". Sets pseudo-variable (string key) in dictionairy with string value. Adds key if doesn't exist.
# - "add quest_name quest_values":. Adds a new quest with quest_values. TODO
# - "end quest_name quest_status": End quest with status (eg. fulfilled, failed) TODO
# TODO: add_Quest in its own key value, NOT in execute, so not all string eg. "add_quest: {"name": "kill", "amount": 5, "mon": "giant rat"} to allow for values
# TODO: move to another, more aptly named singleton.
func execute(act):
	var act_parsed : Array = act.split(" ")
	var command = act_parsed[0].to_lower()
	# First word is always the command keyword, match to pre-scripted options
	if command == "screen":
		# Screen shake
		if act_parsed[1] == "shake":
			emit_signal("screen_shake")
	elif command == "emit_signal":
		# NOTE: signals MUST be defined at the top of this file and match
		# the name of act_parsed[1] exactly to be sent successfuly.
		# Example: act "emit_signal screen_shake"
		# works the same as act "screen shake"
		if act_parsed.size() == 2:
			emit_signal(act_parsed[1])
		elif act_parsed.size() == 3:
			# Emit with String arg
			emit_signal(act_parsed[1], act_parsed[2])
		else:
			# Emit with array args
			emit_signal(act_parsed[1], act_parsed.slice(2, act_parsed.size() - 1))
		print("Emitted signal " + act_parsed[1])
	elif command == "set":
		# Requires three words: command key value. 
		if act_parsed.size() != 3:
			print("WARNING: action " + act + " not set appropriately. Expected three words." + \
						" Recieved " + str(act_parsed.size()))
		# Set custom game data in a dictionary
		var key = act_parsed[1]
		var value = act_parsed[2]
		if not data.has(key):
			print("Created new game data variable " + key + " with value " + value)
		else:
			print("Overwritten game data variable " + key + " to " + value)
		data[key] = value
	# TODO: implement your own custom actions here where act_parsed is the
	# space delineated series of strings determining what action occurs
	# NOTE: Look at src/ for an example with more custom-defined actions.
	else:
		# Action didn't match any presets. A spelling mistake?
		print("Did not understand given action " + act)
	
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
var cutscene = false: get = get_state_cutscene, set = set_state_cutscene
	
func set_state_talking(is_talking):
	talking = is_talking
	if is_talking:
		emit_signal("pause")
	elif not is_paused():
		# This check is necessary in case, for example, talking and cutscene both occur asynch.
		emit_signal("unpause")
	
func get_state_talking():
	return talking
	
func set_state_cutscene(is_cutscene_playing):
	cutscene = is_cutscene_playing
	if is_cutscene_playing:
		emit_signal("pause")
	elif not is_paused():
		emit_signal("unpause")
	
func get_state_cutscene():
	return cutscene
	
# Returns whether game is paused. Manually setting how nodes react to this setting
# allows greater control than get_tree().paused = true
func is_paused():
	return talking or cutscene

func get_next_line():
	pass
