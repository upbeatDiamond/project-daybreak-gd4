# Represents the Battle I/O
extends BattleController
class_name BattleClient

signal summaries_read

var summaries : Array[String] = []
var had_summary := false


enum IOMode{
	BLANK = 0, # Hide the interface
	TEXT = 1, # Hide all but the background, and enable printouts
	TEXT_CONTINUE = 2, # Confirms the current text prompt; used like a State Machine
	HOME = 3, # Show the Fight, Bag, Team, etc menu options
	MOVE = 4, # Show all moves available, and an exit to Main
	BAG = 5, # Show items available, and an exit to Main
	TEAM = 6, # Show teammates, and an exit to Main
	MOVE_TARGET = 7, # Select who gets affected by the move
}

var ui_mode:IOMode = IOMode.TEXT

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


#func _process(delta: float) -> void:
	#
	#if summaries.size() > 0:
		#had_summary = true
	#elif had_summary:
		#had_summary = false
		#summaries_read.emit()


func run_turn(battler:Combatant) -> BattleAction:
	print("My name is ", battler.nname, "[client]")
	return BattleAction.new(BattleAction.ActionType.PASS, battler)


"""
	Prints the next string in the 'summary' array.
	This should be overwritten by child classes (GUI and Terminal)
	
	Returns a string on success, or null on failure.
"""
func _get_next_summary():
	var ret = null
	if summaries.size() >= 1:
		# Remove null entries from front of the array ...
		while ret == null and not summaries.is_empty(): 
			ret = summaries.pop_front() # ... and get the front-most String.
		# If all entries are null, then ret should be null.
		# If there are no entries, then ret is null.
	return ret


func switch_ui_mode(_mode:IOMode):
	ui_mode = _mode


func append_summary(summary:String):
	summaries.append(summary)
