extends Control
class_name Cinematic


signal cinematic_started(cinematic:Cinematic);
signal cinematic_finished(cinematic:Cinematic);

func start_cine():
	cinematic_started.emit(self)
	await _start_cine()
	cinematic_finished.emit(self)

func _start_cine():
	pass
