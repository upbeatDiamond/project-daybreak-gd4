extends Node2D


# Stores the MapNodules, which are used for NPCs passing from 1 scene to another.

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func link_nodules( from:MapNodule, to:MapNodule ):
	from.establish_outlink( to )
	pass
