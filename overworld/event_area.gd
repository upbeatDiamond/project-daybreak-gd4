extends Area2D
class_name EventArea


enum Operator{
	EQUAL,
	UNEQUAL,
	LT_EQUAL,
	GT_EQUAL,
	LESS_THAN,
	GREATER_THAN,
}

## Conditions should compare values, but should account for 
## mathematical comparisons, and thus need parsing out the first symbol.
## Anything after the first symbol doesn't count. 1 symbol != 1 character
@export var conditions : Dictionary = {}


enum ActivationMode {
	ACTIVE_ON_ENTER,
	ACTIVE_ON_INTERACT,
	ACTIVE_ON_TOUCH,
}

var activation_mode := ActivationMode.ACTIVE_ON_ENTER

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_body_entered(body:PhysicsBody2D):
	if activation_mode == ActivationMode.ACTIVE_ON_ENTER and \
			(body is Gamepiece or body.get_groups().has("gamepiece")):
		print("Body entered! ", body)
		run_event(body)
	pass
	

func run_event(gamepiece:Gamepiece):
	assert(false, "Run Event is an abstract class! Implement elsewhere!")


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
				invalidated = not _test_relation(val, Operator.EQUAL, compare)
			"=": ## Equals 2
				compare = str(conditions[key]).split("=",true,1)[1]
				invalidated = not _test_relation(val, Operator.EQUAL, compare)
			
			"!=": ## Not Equals
				compare = str(conditions[key]).split("!=",true,1)[1]
				invalidated = not _test_relation(val, Operator.UNEQUAL, compare)
			
			"<": ## Less Than
				compare = str(conditions[key]).split("<",true,1)[1]
				invalidated = not _test_relation(val, Operator.LESS_THAN, compare)
			
			">": ## Greater Than
				compare = str(conditions[key]).split(">",true,1)[1]
				invalidated = not _test_relation(val, Operator.GREATER_THAN, compare)
			
			"<=": ## Less Than or Equals
				compare = str(conditions[key]).split("<=",true,1)[1]
				invalidated = not _test_relation(val, Operator.LT_EQUAL, compare)
			
			">=": ## Greater Than or Equals
				compare = str(conditions[key]).split(">=",true,1)[1]
				invalidated = not _test_relation(val, Operator.GT_EQUAL, compare)
			
			_: ## Default, same as '==' for now...
				compare = str(conditions[key])#.split("==",true,1)[1]
				invalidated = not _test_relation(val, Operator.EQUAL, compare)
				
		print("cutscene trigger, test relation, ", val, " ={ ", !invalidated ," }= ", compare)
		
		if invalidated:
			return false;
	return true;


func _test_relation(var1, operator:Operator, var2) -> bool:
	
	if var1 == null or (var1 is String and var1 == "<null>"):
		var1 = 0;
	
	if var2 == null or (var2 is String and var2 == "<null>"):
		var2 = 0;
	
	if typeof(var1) == typeof(var2):
		return var1 == var2
	elif str(var1).strip_edges().is_valid_int() and str(var2).strip_edges().is_valid_int():
		return _process_relation(str(var1).to_int(), operator, str(var2).to_int())
	elif str(var1).strip_edges().is_valid_float() and str(var2).strip_edges().is_valid_float():
		return _process_relation( str(var1).to_float(), operator, str(var2).to_float())
	else:
		return _process_relation( str(var1), operator, str(var2) )

func _process_relation(var1, operator:Operator, var2) -> bool:
	match operator:
		Operator.UNEQUAL:
			return var1 != var2
		Operator.LT_EQUAL:
			return var1 <= var2
		Operator.GT_EQUAL:
			return var1 >= var2
		Operator.LESS_THAN:
			return var1 < var2
		Operator.GREATER_THAN:
			return var1 > var2
		_:
			return var1 == var2
