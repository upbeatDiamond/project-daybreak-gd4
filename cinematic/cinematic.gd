extends Control
class_name Cinematic

signal cinematic_started(cinematic:Cinematic);
@warning_ignore("unused_signal") # This signal is used by subclasses
signal cinematic_finished(cinematic:Cinematic);


func start_cine():
	GlobalRuntime.scene_manager.mount_cinematic(self)
	cinematic_started.emit(self)


func _start_cine():
	pass
