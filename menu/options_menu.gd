extends Control

# Following tutorials from:
# https://www.youtube.com/watch?v=PKV_i4kaC0M (GDQuest)
# https://www.youtube.com/watch?v=be-Xjg8oPbQ (rayuse rp)
# https://www.youtube.com/watch?v=QnEG01t2P9M (16BitDev)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_back_pressed():
	GlobalRuntime.clean_up_descent( self )
#	replace_by(  play_scene.instantiate()  )
	queue_free()
	pass # Replace with function body.
