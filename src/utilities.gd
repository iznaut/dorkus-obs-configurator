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
	return ProjectSettings.globalize_path("res://build/win") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir()


static func get_user_config_path() -> String:
	return get_working_dir().path_join("config.ini")


static func get_user_config(section : String, key : String) -> String:
	var config = ConfigFile.new()

	# Load data from a file.
	config.load(get_user_config_path())

	var value = config.get_value(section, key)

	# If the file didn't load, ignore it.
	if value == null:
		return ""

	return value


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


static func start_process(app_path) -> int:
	var output = []
	var params = [
		"$process = Start-Process %s -WorkingDirectory %s -PassThru;" % [app_path, app_path.get_base_dir()],
		"return $process.Id"
	]

	OS.execute("PowerShell.exe", params, output)

	# return process id
	return output[0].replace("\\r\\n", "") as int


static func upload_file_to_frameio(filepath):
	var output = []
	var params = [
		get_user_config("Frameio", "Token"),
		get_user_config("Frameio", "RootAssetID"),
		filepath,
	]

	# use precompiled script exe if shipping build
	var upload_script = Utility.get_working_dir().path_join("obs/dist/windows/frameio_upload.exe")

	# use python script if in editor
	if OS.has_feature("editor"):
		upload_script = "python"
		params.push_front(ProjectSettings.globalize_path("res://support/obs/frameio_upload.py"))

	OS.execute(upload_script, params, output, true, false)

	var result = JSON.parse_string(output[0])

	print(output)

	return result


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
