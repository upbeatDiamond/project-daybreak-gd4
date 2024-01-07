extends Area2D
# This script is not a Gametoken, because/therefore destruction should be forgiven.

var is_destruction_queued:=false
const RAND_LIMIT = 255
var rand_threshhold = 128

# Called when the node enters the scene tree for the first time.
func _ready():
	area_entered.connect(_on_area_entered)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_area_entered(area):
	if area is Gamepiece or area.is_in_group("gamepiece"):
		run_event(area as Gamepiece)
	pass


func run_event( gp:Gamepiece ):
	match gp.traversal_mode:
		Gamepiece.TraversalMode.RUNNING, Gamepiece.TraversalMode.BICYCLING:
			is_destruction_queued = true
			pass
		_:
			pass
	# run important scripts here, and then kill the grass if queued
	roll_spawn_chance()
	#print("woo! Grass has to decide whether to self-destruct / ", gp.traversal_mode)
	if is_destruction_queued:
		self_destruct()
	return true


func self_destruct():
	queue_free()
	pass


func roll_spawn_chance():
	var rn = randi_range(0, RAND_LIMIT)
	if rn > rand_threshhold:
		spawn_monster_fight()
	pass


func spawn_monster_fight():
	pass
