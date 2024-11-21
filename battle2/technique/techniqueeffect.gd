extends Node
class_name TechniqueEffect

enum Category
{
	PHYSICAL,
	SPECIAL,
	STATUS,
}

enum BooleanFlags
{
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

# traits structure: {}
func calculate_effect( _user, _targets:Array, _traits:Dictionary, \
_current_effects:TechniqueResultSummary ):
	pass
