@tool
extends Node


enum StatusType {
	RECORDING_PATH,
	ASSETS_PATH,
}

@export var check_on_ready : bool
@export var status_type : StatusType:
	set(new_type):
		$Label.text = status_config[new_type].label_text

		status_type = new_type

var is_success := false:
	set(new_success):
		$StatusEmoji.text = "✔" if new_success else "❌"
		$Button.visible = !new_success

		is_success = new_success
var status_config = {
	StatusType.RECORDING_PATH: {
		"label_text": "Recording Save Location Set",
		"config_file_key": "profile",
		"default_starting_directory": "D:/Recordings",
		"check_func": func(f_str : String) -> bool: return not f_str.contains("%%RECORDING_PATH%%"),
		"fix_func": func(f_str : String, fix_str : String) -> String: return f_str.replace("%%RECORDING_PATH%%", fix_str),
	},
	StatusType.ASSETS_PATH: {
		"label_text": "OBS Assets Found",
		"config_file_key": "scene",
		"default_starting_directory": "res://dorkus-obs/bin/64bit/",
		"json_paths": {
			"dorkus-white.png": ["sources", 4, "settings", "file"],
			"game-pad.png": ["sources", 0, "settings", "io.layout_file"],
			"game-pad.json": ["sources", 0, "settings", "io.overlay_image"],
		},
		"check_func": check_filepaths_in_json,
		"fix_func": replace_filepaths_in_json,
	},
}

@onready var config = status_config[status_type]


func _ready():
	$Label.text = config.label_text

	if not Engine.is_editor_hint() and check_on_ready:
		is_success = config.check_func.call(
			Utility.read_config_file(config.config_file_key)
		)

	if not check_on_ready:
		$StatusEmoji.text = "❓"
		$Button.show()


func fix_and_verify(new_path : String):
	var original_contents : Variant = Utility.read_config_file(config.config_file_key)	
	var new_contents : Variant = config.fix_func.call(original_contents, new_path)

	Utility.write_config_file(config.config_file_key, new_contents)
	is_success = config.check_func.call(new_contents)


func check_filepaths_in_json(json_contents : Dictionary):
	for file_name in config.json_paths.keys():
		var current_value = _find_json_path(json_contents, config.json_paths[file_name].duplicate())

		if not FileAccess.file_exists(current_value):
			return false
	
	return true


func replace_filepaths_in_json(json_contents : Dictionary, new_path : String):
	for file_name in config.json_paths.keys():
		_find_json_path(json_contents, config.json_paths[file_name].duplicate(), new_path + "/" + file_name)

	return json_contents


func _find_json_path(dict, keypath, value = null):
	var current = keypath[0]
	if dict.has(current):
		print(typeof(dict[current]))
		if typeof(dict[current]) == TYPE_DICTIONARY:
			keypath.remove(0)
			_find_json_path(dict[current], keypath, value) # recursion happens here
			return
		elif typeof(dict[current]) == TYPE_ARRAY:
			keypath.pop_front()
			print(keypath)
			_find_json_path(dict[current], keypath, value) # recursion happens here
			return
		else:
			print(value)
			if value:
				dict[current] = value
				return
			return dict[current]


func _on_button_pressed():
	get_viewport().set_embedding_subwindows(false)
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	add_child(dialog)
	dialog.current_dir = config.default_starting_directory
	dialog.position = Vector2(800, 800)
	dialog.size = Vector2(800, 800)
	dialog.visible = true

	dialog.dir_selected.connect(fix_and_verify)
