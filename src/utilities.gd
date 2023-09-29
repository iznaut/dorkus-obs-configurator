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


# convert relative path to absolute (respecting dev/prod working directory difference)
static func globalize_subpath(relative_path : String = "") -> String:
	var path : String

	if OS.has_feature("template"):
		path = OS.get_executable_path().get_base_dir().path_join(relative_path)
	else:
		path = ProjectSettings.globalize_path("res://build/win").path_join(relative_path)
	
	assert(
		DirAccess.dir_exists_absolute(path.get_base_dir()),
		"Directory does not exist (%s)" % path
	)

	return path


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
			var new_filepath = root_dir.path_join("config/assets").path_join(map[item])

			assert(FileAccess.file_exists(new_filepath), "Could not find %s at expected path" % map[item])

			set_json_path(json_contents, keypath, new_filepath)

	return json_contents


static func copy_directory_recursively(p_from : String, p_to : String) -> void:
	if not DirAccess.dir_exists_absolute(p_to):
		DirAccess.make_dir_recursive_absolute(p_to)
	
	var dir = DirAccess.open(p_from)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != "" && file_name != "." && file_name != ".."):
			if dir.current_is_dir():
				copy_directory_recursively(p_from.path_join(file_name), p_to.path_join(file_name))
			else:
				dir.copy(p_from.path_join(file_name), p_to.path_join(file_name))
			file_name = dir.get_next()
	else:
		push_warning("Error copying " + p_from + " to " + p_to)


static func create_gdignore(dir_to_ignore : String):
	var new_file = FileAccess.open(dir_to_ignore.path_join(".gdignore"), FileAccess.WRITE)
	new_file.close()


static func os_execute_async(app_path : String, params : Array) -> Variant:
	var output = []

	var thread = Thread.new()
	thread.start(
		func():
			OS.execute(app_path, params, output)

			if app_path == "Powershell.exe":
				output = output[0].replace("\\r\\n", "") as int

			print("execute output:")
			print(output)

			return output
	)

	return thread.wait_to_finish()
