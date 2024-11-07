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
	pass


func _on_external_variable_update(key:String, value) -> void:
	set_key_value(key,value)


func _on_external_variable_fetch(key:String):
	get_key_value(key)


# return the value for a key
func get_key_value( key:String ):
	if key_values.has(key):
		return key_values[key]
	return null


func set_key_value( key:String, value ):
	key_values[key] = value


# Parameters:
# duration - length in seconds to wait for
func ev_wait( parameters ):
	if parameters.has("duration"):
		await get_tree().create_timer( parameters["duration"] ).timeout
