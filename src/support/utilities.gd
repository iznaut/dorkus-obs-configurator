extends Node
class_name Utility

static func read_json(filepath) -> Dictionary:
	var file = FileAccess.open(filepath, FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	return json.get_data()


static func write_json(filepath, obj : Dictionary) -> void:
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	file.store_string(JSON.stringify(obj))


static func read_ini(filepath : String):
	var config = ConfigFile.new()
	var err = config.load(filepath)

	if err != OK:
		return

	return config


static func read_config_file(config_key : String) -> Variant:
	var paths := read_json("res://paths.json")
	var filepath : String = paths[config_key]

	if filepath.get_file().get_extension() == "json":
		return read_json(filepath)
	else:
		return read_ini(filepath)


static func write_config_file(config_key : String, new_contents : Variant):
	var paths := read_json("res://paths.json")
	var filepath : String = paths[config_key]

	if filepath.get_file().get_extension() == "json" and new_contents is Dictionary:
		var file = FileAccess.open(filepath, FileAccess.WRITE)
		new_contents = JSON.stringify(new_contents)
		file.store_string(new_contents)
		file.close()
	else:
		new_contents.save(filepath)


static func globalize_path(path : String) -> String:
	var is_user_path = path.contains("user://")
	var uri = "user://" if is_user_path else "res://"

	path = path.replace(uri, "")

	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path(uri + path)
	else:
		return OS.get_executable_path().get_base_dir().path_join(path)


static func get_user_config(section : String, key : String) -> String:
	var config = ConfigFile.new()

	# Load data from a file.
	config.load("user://user.cfg")

	var value = config.get_value(section, key)

	# If the file didn't load, ignore it.
	if value == null:
		return ""

	return value


static func set_user_config(section : String, key : String, value : String) -> void:
	var config = ConfigFile.new()

	config.load("user://user.cfg")
	config.set_value(section, key, value)
	config.save("user://user.cfg")
