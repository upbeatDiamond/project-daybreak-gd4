extends EventArea

@export var screenplay : String
@export var scene : String

## If true, walking into it starts the screenplay.
## If false, it should hint that interaction is available.
@export var active_on_enter = false

## This should be backed up by the database, to prevent unneeded replays
@export var enabled := true

## This should not be backed up, it should be relatively constant
@export var one_shot := true




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	#if enabled and one_shot and active_on_enter:
		#var areas = get_overlapping_areas()
		#for area in areas:
			#if area is Gamepiece:
				#run_event( area )
	#el
	if one_shot and not enabled:
		self.queue_free()
	pass


func run_event( gamepiece:Gamepiece ):
	
	# Early exit, to decrease ability for multiple cutscenes to occur at once
	if GlobalDirector.is_paused():
		return
	
	# Early exit, to enable cutscenes to be disabled
	if not _match_conditions():
		return
	
	var areas = get_overlapping_areas()
	if (gamepiece not in areas) or not enabled:
		return
	
	if one_shot:
		enabled = false
	
	GlobalDirector.run_screenplay(screenplay, scene)
	pass
