extends Area2D
# This should be an instance or child of a gametoken

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func run_event( gamepiece:Gamepiece ):
	
	# get gamepiece's relative position and/or raycast
	# copy this to raycast to a new position
	# If valid, move there
	# If invalid b/c gamepiece, push gamepiece (parallel, else perpendicular)
		# If gamepiece cannot be pushed, swap with gamepiece
	# If any other intrusion, do not allow push
	
	pass
