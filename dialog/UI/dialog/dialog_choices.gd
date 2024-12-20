"""
DialogChoices recieves an array of choices and creates buttons for each choices
with cooresponding next dialog id accordingly. Visibility is controlled by parent dialog UI.

Dependencies:
	GlobalDialog.END_DIALOG_ID

Info:
	Godot Open Dialogue System
	by Tina Qin (QueenChristina)
	https://github.com/QueenChristina/gd_dialog
	License: MIT.
	Please credit me if you use! Thank you! <3
"""

extends HBoxContainer
class_name DialogChoices

signal choice_selected(index:int)

@onready var button_container = $VBox
@onready var button_sound = self.owner.get_node("ButtonSound")

# TODO: If choices text short, then add columns instead of rows, looks nicer for Yes/No.
# (1) Add HBox + Button if choices total text length is short enough (horizontal style)
# (2) Add VBox + Button if choices text length is long (column style)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Creates and connects each button in the button container, representing choices.
# 	choices - an array of format: 
#	[{	"text" : "choice_text", 
#		"next" : "next_dialog_id", 
#		"action" : "what to do on choice selected"
#		"show_only_if" : "show this choice only if this condition is met"}]
func set_buttons(choices):
	# Delete old choices from previous dialogs.
	for button in button_container.get_children():
		button.queue_free()
	# Populate with current choices.
	
	for i in range(choices.size()):
		var choice = choices[i]
		if not ("show_only_if" in choice) or \
			("show_only_if" in choice and GlobalDirector.is_condition_met(choice["show_only_if"])):
			# Show choice button if there is no conditional.
			# If there is a condition, only show choice if the condition in show_only_if is met.
			var button = Button.new()
			if choice is Dictionary and "label" in choice:
				button.text = choice["label"]
			else:
				button.text = str("option ", i)
			button_container.add_child(button)
			var next_id = i
			var action = null
			if "action" in choice:
				action = choice["action"]
			button.connect("pressed", Callable(self, "_on_button_pressed").bind(next_id, action))
			button.connect("focus_entered", Callable(button_sound, "_on_choice_hovered"))
			button.connect("mouse_entered", Callable(button_sound, "_on_choice_hovered"))
	
	#for choice in choices:
		#if not ("show_only_if" in choice) or \
			#("show_only_if" in choice and GlobalDialog.is_condition_met(choice["show_only_if"])):
			## Show choice button if there is no conditional.
			## If there is a condition, only show choice if the condition in show_only_if is met.
			#var button = Button.new()
			#button.text = choice["text"]
			#button_container.add_child(button)
			#var next_id = choice["next"]
			#if next_id == "" :
				#next_id = GlobalDialog.END_DIALOG_ID
			#var action = null
			#if "action" in choice:
				#action = choice["action"]
			#button.connect("pressed", Callable(self, "_on_button_pressed").bind(next_id, action))
			#button.connect("focus_entered", Callable(button_sound, "_on_choice_hovered"))
			#button.connect("mouse_entered", Callable(button_sound, "_on_choice_hovered"))
	# Error checking; expect to have at least one visible choice.
	if choices.size() > 0 and button_container.get_child_count() == 0:
		print("WARNING: No choices set. Check your conditionals.")

func _on_button_pressed(index:int, action):
	# Execute actions associated with choosing button choice.
	if action:
		for act in action:
			print("Execute " + act)
			GlobalDirector.execute(act)
	emit_signal("choice_selected", index)
