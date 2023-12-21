extends Node
class_name TechniqueEffect


var type_primary
var type_secondary

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

enum BooleanFlags
{
}

# traits structure: {}
func _calculate_effect( user, targets : Array, traits : Dictionary, current_effects : TechniqueResultSummary ):
	pass
