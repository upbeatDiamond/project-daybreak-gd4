extends Area2D

@export var width := 1 :
	set(value):
		self.scale.x = width
		width = (value) as int
	get:
		return width

@export var height := 1 :
	set(value):
		self.scale.y = height
		height = (value) as int
	get:
		return height

#@export_file("*.tscn") var map = null;
@export var map : String = "";

@export var target_position : Vector2i
@export var target_facing : Vector2i

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_entered(area):
	if area is Gamepiece or area.is_in_group("gamepiece"):
		area.set_teleport(target_position, target_facing)
	pass # Replace with function body.
