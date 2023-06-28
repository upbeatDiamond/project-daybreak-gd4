extends TextureRect

@export var icon_full := preload("res://assets/textures/gui/combat/Psych_Full.png")
@export var icon_empty := preload("res://assets/textures/gui/combat/Psych_Empty.png")

@export var active_default := false
var image_uptodate := false

var is_exhausted := false  :
	get:
		return is_exhausted
	set(value):
		is_exhausted = value
		update_icon()
	

# Called when the node enters the scene tree for the first time.
func _ready():
	update_icon()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Make a script to switch between states using an animation
# Make a setget to do that ^ 

func update_icon():
	if active_default != is_exhausted:
		self.texture = icon_full
		image_uptodate = true
	else:
		self.texture = icon_empty
		image_uptodate = true
	pass # Replace with function body.
