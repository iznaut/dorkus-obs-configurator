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


static func get_working_dir() -> String:
	return ProjectSettings.globalize_path("res://") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir()


static func get_config_path():
	return get_working_dir().path_join("config.ini")


static func does_config_exist():
	return FileAccess.file_exists(get_config_path())


static func globalize_path(path : String) -> String:
	var is_user_path = path.contains("user://")
	var uri = "user://" if is_user_path else "res://"

	path = path.replace(uri, "")

	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path(uri + path)
	else:
		if is_user_path:
			return path
		else:
			return OS.get_executable_path().get_base_dir().path_join(path)


static func get_user_config(section : String, key : String) -> String:
	var config = ConfigFile.new()

	# Load data from a file.
	config.load(get_config_path())

	var value = config.get_value(section, key)

	# If the file didn't load, ignore it.
	if value == null:
		return ""

	return value


static func set_user_config(section : String, key : String, value : String) -> void:
	var config = ConfigFile.new()
	var config_path = get_config_path()

	config.load(config_path)
	config.set_value(section, key, value)
	config.save(config_path)


static func get_json_index(source_id : String, json_contents : Dictionary) -> int:
	var index := 0

	for source in json_contents.sources:
		if source.id == source_id:
			return index

		index += 1
	
	return -1


static func set_json_path(dict, keypath, value) -> Variant:
	var current = keypath[0]
	if typeof(dict[current]) == TYPE_DICTIONARY:
		keypath.remove_at(0)
		set_json_path(dict[current], keypath, value) # recursion happens here
		return
	elif typeof(dict[current]) == TYPE_ARRAY:
		keypath.remove_at(0)
		set_json_path(dict[current], keypath, value) # recursion happens here
		return
	else:
		dict[current] = value
		return


static func replace_filepaths_in_json(root_dir : String, json_contents : Dictionary, remaps) -> Dictionary:
	for id in remaps.keys():
		var map = remaps[id]
		var index = get_json_index(id, json_contents)

		for item in map.keys():
			var keypath = ["sources", index, "settings", item]
			var new_filepath = root_dir.path_join("assets").path_join(map[item])

			assert(FileAccess.file_exists(new_filepath), "Could not find %s at expected path" % map[item])

			set_json_path(json_contents, keypath, new_filepath)

	return json_contents


static func start_process(app_path) -> int:
		var output = []
		var params = [
				"%s \"%s\" \"%s\"" % [Utility.globalize_path("res://support/start_process.ps1"), app_path, app_path.get_base_dir()]
			]

		OS.execute(
			"PowerShell.exe",
			params,
			output
		)

		print(params)

		return output[0].replace("\\r\\n", "") as int


static func upload_file_to_frameio(filepath):
		var output = []

		OS.execute(
			"python3",
			[
				Utility.globalize_path("res://support/frameio_upload.py"),
				get_user_config("Frameio", "Token"),
				get_user_config("Frameio", "ProjectID"),
				filepath,
			],
			output
		)

		return JSON.parse_string(output[0])


static func find_by_class(node: Node, className : String, result : Array) -> void:
	if node.is_class(className):
		result.push_back(node)
	for child in node.get_children():
		find_by_class(child, className, result)
