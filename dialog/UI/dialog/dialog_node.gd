"""
A DialogNode represents a single node indexed by id in the dialogue database
It tracks:
	- name, icon, text, choices, next_id, and other dialog node information.
See Data/Dialogue.json for an example of required dialog node formatting.

Dependencies:
	GlobalDialog.db_dialog, GlobalDialog.END_DIALOG_ID

Info:
	Godot Open Dialogue System
	by Tina Qin (QueenChristina)
	https://github.com/QueenChristina/gd_dialog
	License: MIT.
	Please credit me if you use! Thank you! <3
"""
extends Node
class_name DialogNode

const PAUSE_CHAR := "|" 	# Character to replace with a pause.
const NAME_CHAR := "&"		# Character to replace with player name.

var id := ""				# Current dialog id
var next_id := "end"		# Next dialog id following this. Defaults to end dialog.
var speaker := "" 			# The name displayed in name box (optional)
var voice := "default" 		# Voice key should match key in voices database, sound of dialog. Assumes a default voice exits.
var icon := "none"	# Icon expression, should match animation name of Icon to show (optional)
var texts := []  			# Array of text strings shown in succcession in textbox
var text_index : int = 0	# Texts[text_index] is the current text string to display in textbox
var printable_text := ""	# Actual displayed text in text box; it replaces special characters accordingly
var pause_counts := {} 		# Counts number of PAUSE_CHAR at given printable char index.
var choices := []			# Choices player can choose in dialog. (optional)
var action := []			# Action executed at end of text dialog. (optional)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	next_id = GlobalDirector.END_DIALOG_ID

# Initializes a dialogNode with given dialog id, curr_id
#	curr_id - the id of this DialogNode, assumes key matching curr_id exists in GlobalDialog.db_dialog
func init(curr_line:Dictionary):
	set_default_values()
	
	if "id" in curr_line:
		speaker = str(curr_line["id"])
	#id = curr_id
	#var curr_dialog = GlobalDialog.db_dialog[id]
	if "speaker" in curr_line:
		speaker = str(curr_line["speaker"])
	if "voice" in curr_line:
		voice = curr_line["voice"]
	if "icon" in curr_line:
		icon = curr_line["icon"]
		
	if "options" in curr_line:
		# next_id is not used if choices are used
		choices = curr_line["options"]
	else:
		if "type" in curr_line and curr_line["type"] != "end":
			next_id = "go"
		else:
			next_id = "end"
			#if curr_dialog["next"] is String:
				#next_id = curr_dialog["next"]
			#else:
				## Want to set next_id based on conditionals (an array of dictionaries)
				#var nexts = curr_dialog["next"]
				## ASSUMES: The default next_id must always be the last element, and a string.
				#next_id = nexts[nexts.size() - 1]
				#if nexts.size() > 1:
					## Set the next_id according to conditionals, in order (left to right) of
					## increasing precedence. Assumes each is a dictionary {"id" : "next_id", "if" : "condition"} 
					## Defaults to last next_id (a string) if no conditions are met.
					#for next in nexts.slice(0, nexts.size() - 2):
						#if GlobalDialog.is_condition_met(next["if"]):
							#next_id = next["id"]

	#if "action" in curr_line:
		#action = curr_dialog["action"]
	if "text" in curr_line:
		texts = [curr_line["text"]]
	elif "name" in curr_line:
		texts = [curr_line["name"]]
	else:
		texts = ["..."]
	#var text = texts[text_index]
	printable_text = str(texts[0])#convert_printable(text)
	
func set_default_values():
	id = ""				# Current dialog id
	next_id = "end"		# Next dialog id following this. Defaults to end dialog.
	speaker = "" 			# The name displayed in name box (optional)
	voice = "default" 		# Voice key should match key in voices database, sound of dialog. Assumes a default voice exits.
	icon = "none"	# Icon expression, should match animation name of Icon to show (optional)
	texts = []  			# Array of text strings shown in succcession in textbox
	text_index = 0	# Texts[text_index] is the current text string to display in textbox
	printable_text = ""	# Actual displayed text in text box; it replaces special characters accordingly
	pause_counts = {} 		# Counts number of PAUSE_CHAR at given printable char index.
	choices = []			# Choices player can choose in dialog. (optional)
	action = []
	
# Attemps to advance to the next text index.
# Returns whether we were able to set next text index.
# Returns false if no more text to show in this dialogNode.
func set_next_text_index() -> bool:
	text_index += 1
	if text_index >= texts.size():
		# No more text to show; move to next dialog id
		return false
	# Set current printable text based on text index, current displayed text
	var text = texts[text_index]
	printable_text = convert_printable(text)
	return true
	
# Converts and returns a printable verson of text by replacing special characters:
# 	PAUSE_CHAR is omitted
# 	NAME_CHAR is replaced by character name
func convert_printable(text):
	# (A) Replace NAME_CHAR with name
	var printable = text
	printable = printable.replace(NAME_CHAR, GlobalDirector.player_name)
	
	# (B) Get indexes (text character) just before which to pause, with value of how 
	# long to pause for (count of how many PAUSE_CHAR).
	# NOTE: The key "index" in pause_counts is index based on get_total_character_count() of a richLabelText
	# NOT including bbcode text and also NOT including newlines (so, the index that works with .visible characters)
	pause_counts = {}
	# (1) Get the printable (displayed) text stripped of extra bbcode tags.
	var printable_label  = RichTextLabel.new()
	printable_label.text = printable
	printable_label.parse_bbcode(printable)
	#var printable_stripped_bbcode = printable_label.text # Does not include bbcode text, but does include newlines
	# (2) Count number of PAUSE_CHAR at indexes in which they appear.
	#while PAUSE_CHAR in printable_stripped_bbcode:
		## Set index : count in pause_counts, based on index in text (excludes count of bbcode tags)
		#var curr_pause_index : int = printable_stripped_bbcode.find(PAUSE_CHAR)
		#var num_newline_sofar = printable_stripped_bbcode.count("\n", 0, curr_pause_index)
		#if not pause_counts.has(curr_pause_index):
			## Subtracting newlines is somewhat hacky, but works due to discrepency between
			## Godot's text stripped of bbcode, and visible characters (since \n is not a visible character)
			#pause_counts[curr_pause_index - num_newline_sofar] = 1
		#else:
			#pause_counts[curr_pause_index - num_newline_sofar] += 1
		#printable_stripped_bbcode.erase(curr_pause_index, PAUSE_CHAR.length())
	
	printable = printable.replace(PAUSE_CHAR, "")
	printable_label.queue_free()
	return printable

# Returns for how many counts to pause just before the specified index.
# 	count is calculated by number of PAUSE_CHAR at the index.
# 	count of 0 would mean do not pause here.
# 	The time to pause would be PAUSE_TIME * count.
func pause_count_at(index):
	if pause_counts.has(index):
		return pause_counts[index]
	return 0
