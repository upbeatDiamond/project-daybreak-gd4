extends Node
# Note for the archivists: This is being merged with the Experimental Controller.

var gamepiece : Gamepiece



func _ready() -> void:
	gamepiece = self.get_parent() as Gamepiece
	
	update_configuration_warnings()
	set_physics_process(true)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not get_parent() is Gamepiece:
		warnings.append("Controller must be a child of a Gamepiece to function!")
	
	return warnings


func _physics_process(delta):
	if GlobalRuntime.gameworld_input_stopped || gamepiece.is_paused:
		return
	elif gamepiece.is_moving == false:
		pass#handle_movement_input()


func assign_target_position( target:Vector2 ):
	gamepiece.target_position = gamepiece.snap_to_grid( target )
	if gamepiece.position != gamepiece.target_position:
		pass
