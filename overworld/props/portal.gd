extends Area2D
class_name Portal

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

# By default, use 0 or -1 if "blank", and always use position and facing as backup
@export var keycard_id : int = -1		# -1 = invalid/none, 0 = none/locked, 1+ = real
@export var target_anchor_name : String
@export var target_position : Vector2i	# Fallback value, be warned of map changes
@export var target_facing : Vector2i	# Fallback value, be warned of map changes
@export var is_silent :=true			# if not "silent", then play transition fx (vfx + sfx)

# an id for linking; make sure target_facing can be multiplied by -1 without invalid positioning
@export var portal_id : int				# use with the Enabled bool
@export var enabled : bool				# flip based on player progress

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_area_entered(area):
	if (area is Gamepiece or area.is_in_group("gamepiece")) and validate_keycard(area):
		area.set_teleport(target_position, target_facing, map, target_anchor_name)
	pass # Replace with function body.


func validate_keycard(gp:Gamepiece) -> bool:
	if keycard_id > 0:
		return gp.monster.keycard & (0b01 << keycard_id) != 0
	return true


func run_event( area ):
	_on_area_entered(area)
