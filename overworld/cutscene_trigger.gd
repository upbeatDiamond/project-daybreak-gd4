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


## True if fulfilled
## False if unfulfilled
func _match_conditions() -> bool:
	
	var invalidated := false
	
	for key in conditions.keys():
		var val = GlobalDatabase.load_keyval(key)
		var compare #= str(conditions[key]).split("==",true,1)[1]
		
		# Match the first symbol in the string
		match str(conditions[key]).strip_edges().split(" ")[0]: 
			"==": ## Equals
				compare = str(conditions[key]).split("==",true,1)[1]
				if val == null or val == "<null>":
					val = 0;
				if compare == null or compare == "<null>":
					compare = 0;
				if str(val).strip_edges().is_valid_int() and str(compare).strip_edges().is_valid_int():
					invalidated = not (str(val).to_int() == str(compare).to_int())
				elif str(val).strip_edges().is_valid_float() and str(compare).strip_edges().is_valid_float():
					invalidated = not (str(val).to_float() == str(compare).to_float())
				else:
					invalidated = ( typeof(val) != typeof(compare) )
			"=": ## Equals 2
				compare = str(conditions[key]).split("=",true,1)[1]
				if val == null or val == "<null>":
					val = 0;
				if compare == null or compare == "<null>":
					compare = 0;
				if str(val).strip_edges().is_valid_int() and str(compare).strip_edges().is_valid_int():
					invalidated = not (str(val).to_int() == str(compare).to_int())
				elif str(val).strip_edges().is_valid_float() and str(compare).strip_edges().is_valid_float():
					invalidated = not (str(val).to_float() == str(compare).to_float())
				else:
					invalidated = ( typeof(val) != typeof(compare) )
			
			"!=": ## Not Equals
				compare = str(conditions[key]).split("!=",true,1)[1]
				if val == null or val == "<null>":
					val = 0;
				if compare == null or compare == "<null>":
					compare = 0;
				if str(val).strip_edges().is_valid_int() and str(compare).strip_edges().is_valid_int():
					invalidated = not (str(val).to_int() != str(compare).to_int())
				elif str(val).strip_edges().is_valid_float() and str(compare).strip_edges().is_valid_float():
					invalidated = not (str(val).to_float() != str(compare).to_float())
				else:
					invalidated = ( typeof(val) == typeof(compare) and val == compare)
			
			
			"<": ## Less Than
				compare = str(conditions[key]).split("<",true,1)[1]
				if val == null or val == "<null>":
					val = 0;
				if compare == null or compare == "<null>":
					compare = 0;
				if str(val).strip_edges().is_valid_int() and str(compare).strip_edges().is_valid_int():
					invalidated = not (str(val).to_int() < str(compare).to_int())
				elif str(val).strip_edges().is_valid_float() and str(compare).strip_edges().is_valid_float():
					invalidated = not (str(val).to_float() < str(compare).to_float())
				else:
					invalidated = ( typeof(val) != typeof(compare) )
					print("Warning! Non-integers compared! ", val, "<", compare)
			
			">": ## Greater Than
				compare = str(conditions[key]).split(">",true,1)[1]
				if val == null or val == "<null>":
					val = 0;
				if compare == null or compare == "<null>":
					compare = 0;
				if val is int:
					invalidated = not (val > compare.to_int())
				elif val is float:
					invalidated = not (val > compare.to_float())
				else:
					invalidated = ( typeof(val) != typeof(compare) )
					print("Warning! Non-integers compared! ", val, ">", compare)
			
			"<=": ## Less Than or Equals
				compare = str(conditions[key]).split("<=",true,1)[1]
				if val == null or val == "<null>":
					val = 0;
				if compare == null or compare == "<null>":
					compare = 0;
				if val is int:
					invalidated = not (val <= compare.to_int())
				elif val is float:
					invalidated = not (val <= compare.to_float())
				else:
					invalidated = ( typeof(val) != typeof(compare) )
					print("Warning! Non-integers compared! <=")
			
			">=": ## Greater Than or Equals
				compare = str(conditions[key]).split("==",true,1)[1]
				if val == null or val == "<null>":
					val = 0;
				if compare == null or compare == "<null>":
					compare = 0;
				if val is int:
					invalidated = not (val >= compare.to_int())
				elif val is float:
					invalidated = not (val >= compare.to_float())
				else:
					invalidated = ( typeof(val) != typeof(compare) )
					print("Warning! Non-integers compared! >=")
			
			_: ## Default, same as '==' for now...
				compare = str(conditions[key])#.split("==",true,1)[1]
				if str(val).strip_edges().is_valid_int() and str(compare).strip_edges().is_valid_int():
					invalidated = not (str(val).to_int() == str(compare).to_int())
				elif str(val).strip_edges().is_valid_float() and str(compare).strip_edges().is_valid_float():
					invalidated = not (str(val).to_float() == str(compare).to_float())
				else:
					invalidated = ( typeof(val) != typeof(compare) or val == compare)
		
		print("cutscene trigger, test relation, ", val, " ={ ", !invalidated ," }= ", compare)
		
		if invalidated:
			return false;
	return true;
