# import_plugin.gd
@tool
extends EditorImportPlugin


func _get_importer_name():
	return "db.importer.wowzers"

func _get_visible_name():
	return "DB Importer"

func _get_recognized_extensions():
	return ["db"]


func _get_import_options(_path, _preset_index):
	match _preset_index:
		_:
			return []

func _get_save_extension():
	return "res"

func _get_resource_type():
	return "Database"

func _get_priority():
	return 2

func _get_import_order():
	return 0

func _get_preset_count():
	pass

func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()

	var line = file.get_line()

	return ResourceSaver.save(Database.new(), "%s.%s" % [save_path, _get_save_extension()])
