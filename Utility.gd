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


static func read_config_file(config_key : String) -> Variant:
	var paths := read_json("res://paths.json")
	var filepath : String = paths[config_key]

	var file = FileAccess.open(filepath, FileAccess.READ)
	var file_contents = file.get_as_text()
	file.close()

	if filepath.get_file().get_extension() == "json":
		var json = JSON.new()
		json.parse(file_contents)
		return json.get_data()

	return file_contents


static func write_config_file(config_key : String, new_contents : Variant):
	var paths := read_json("res://paths.json")
	var filepath : String = paths[config_key]

	var file = FileAccess.open(filepath, FileAccess.WRITE)

	if filepath.get_file().get_extension() == "json" and new_contents is Dictionary:
		new_contents = JSON.stringify(new_contents)
	
	file.store_string(new_contents)
	file.close()
