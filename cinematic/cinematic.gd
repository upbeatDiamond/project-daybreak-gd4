extends Control
class_name Cinematic

signal cinematic_started(cinematic:Cinematic);
signal cinematic_finished(cinematic:Cinematic);

func start_cine():
	GlobalRuntime.scene_manager.mount_cinematic(self)
	cinematic_started.emit(self)

func _start_cine():
	pass
