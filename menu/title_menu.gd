extends Control

@export var play_scene = preload("res://overworld/red_town.tscn") :
	get:
		return play_scene
	set( value ):
		if value.contains("res://"):
			play_scene = load(value)
		else:
			play_scene = get_node(value)

@export var options_menu = preload("res://menu/options_menu.tscn")

func _ready():
	pass


func _on_play_pressed():
	GlobalRuntime.clean_up_descent( self )
	replace_by(  play_scene.instantiate()  )
	queue_free()
	pass # Replace with function body.


func _on_options_pressed():
	#GlobalRuntime.clean_up_descent( self )
	#replace_by(  options_menu.instantiate()  )
	#queue_free()
	pass # Replace with function body.


func _on_connection_pressed():
	pass # Replace with function body.


func _on_quit_pressed():
	get_tree().quit()


func _on_credits_pressed():
	pass # Replace with function body.
