extends Area2D

@export var screenplay : String
@export var scene : String

## If true, walking into it starts the screenplay.
## If false, it should hint that interaction is available.
@export var active_on_enter = false

## Conditions should compare values, but should account for 
## mathematical comparisons, and thus need parsing out the first symbol.
## Anything after the first symbol doesn't count. 1 symbol != 1 character
@export var conditions : Dictionary = {}

## This should be backed up by the database, to prevent unneeded replays
@export var enabled := true

## This should not be backed up, it should be relatively constant
@export var one_shot := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if enabled and one_shot and active_on_enter:
		var areas = get_overlapping_areas()
		for area in areas:
			if area is Gamepiece:
				run_event( area )
	elif one_shot and not enabled:
		self.queue_free()
	pass


func run_event( gamepiece:Gamepiece ):
	
	# Early exit, to decrease ability for multiple cutscenes to occur at once
	if GlobalDirector.is_paused():
		return
	var areas = get_overlapping_areas()
	if (gamepiece not in areas) or not enabled:
		return
	
	if one_shot:
		enabled = false
	
	GlobalDirector.run_screenplay(screenplay, scene)
	pass


## True if fulfilled
## False if unfulfilled
func _match_conditions() -> bool:
	
	var invalidated := false
	
	for key in conditions.keys():
		var val = GlobalDatabase.load_keyval(key)
		var compare
		
		# Match the first symbol in the string
		match str(conditions[key]).strip_edges().split(" "): 
			"==": ## Equals
				compare = str(conditions[key]).split("==",true,1)
				if val is int:
					invalidated = not (val == compare.to_int())
				elif val is float:
					invalidated = not (val == compare.to_float())
				else:
					invalidated = not (val == compare)
			
			"<": ## Less Than
				compare = str(conditions[key]).split("<",true,1)
				if val is int:
					invalidated = not (val < compare.to_int())
				elif val is float:
					invalidated = not (val < compare.to_float())
				else:
					invalidated = not (val == compare)
					print("Warning! Non-integers compared! <")
			
			">": ## Greater Than
				compare = str(conditions[key]).split(">",true,1)
				if val is int:
					invalidated = not (val > compare.to_int())
				elif val is float:
					invalidated = not (val > compare.to_float())
				else:
					invalidated = not (val == compare)
					print("Warning! Non-integers compared! >")
			
			"<=": ## Less Than or Equals
				compare = str(conditions[key]).split("==",true,1)
				if val is int:
					invalidated = not (val <= compare.to_int())
				elif val is float:
					invalidated = not (val <= compare.to_float())
				else:
					invalidated = not (val == compare)
					print("Warning! Non-integers compared! <=")
			
			">=": ## Greater Than or Equals
				compare = str(conditions[key]).split("==",true,1)
				if val is int:
					invalidated = not (val >= compare.to_int())
				elif val is float:
					invalidated = not (val >= compare.to_float())
				else:
					invalidated = not (val == compare)
					print("Warning! Non-integers compared! >=")
			
			_: ## Default, same as '==' for now...
				compare = str(conditions[key]).split("==",true,1)
				if val is int:
					invalidated = not (val == compare.to_int())
				elif val is float:
					invalidated = not (val == compare.to_float())
				else:
					invalidated = not (val == compare)
		
		if invalidated:
			return false;
	return true;
