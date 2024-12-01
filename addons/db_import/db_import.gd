@tool
extends EditorPlugin


var import_plugin

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	import_plugin = preload("db_import_plugin.gd").new()
	add_import_plugin(import_plugin)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_import_plugin(import_plugin)
	import_plugin = null
