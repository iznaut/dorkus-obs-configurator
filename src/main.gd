extends Node

signal main_ready

const STATUS_WINDOW := preload("res://src/assistant/dorkus_assistant.tscn")

@export var app_toggle_container : NodePath

var status_window : Control

@onready var obs_helper = $OBSHelper


func _ready():
	DisplayServer.window_set_title("Dorkus Dashboard")

	fix_sources()
	get_tree().set_auto_accept_quit(false)
	# get_viewport().set_embedding_subwindows(false)

	status_window = STATUS_WINDOW.instantiate()

	var window = Window.new()
	# window.hide()
	window.size = Vector2i(640,480)
	window.add_child(status_window, true)
	add_child(window)

	# var window = status_window.window

	window = window.get_viewport()
	window.title = "Dorkus Assistant"
	window.always_on_top = true
	window.transparent = true
	window.transparent_bg = true
	window.borderless = true
	var res := DisplayServer.screen_get_size()
	window.position = res - window.size + Vector2i(0, res.y / 2 - 20)
	print(window.position)
	obs_helper.replay_buffer_saved.connect(status_window._on_replay_buffer_saved)
	window.show()


func fix_sources():
	var original_contents : Variant = Utility.read_json(Config.path_to_obs_scene)
	Utility.write_json(Config.path_to_obs_scene, replace_filepaths_in_json(original_contents))


func replace_filepaths_in_json(json_contents : Dictionary) -> Dictionary:
	for source_id in Config.source_remaps.keys():
		var source_map = Config.source_remaps[source_id]
		var source_index = _get_source_index(source_id, json_contents)

		for item in source_map.keys():
			var keypath = ["sources", source_index, "settings", item]
			var new_filepath = "dorkus-obs/assets/" + source_map[item]

			assert(FileAccess.file_exists(new_filepath), "Could not find %s at expected path" % source_map[item])

			_set_json_path(json_contents, keypath, Utility.globalize_path(new_filepath))

	return json_contents


func _get_source_index(source_id : String, json_contents : Dictionary) -> int:
	var index := 0

	for source in json_contents.sources:
		if source.id == source_id:
			return index

		index += 1
	
	return -1


func _set_json_path(dict, keypath, value) -> Variant:
	var current = keypath[0]
	if typeof(dict[current]) == TYPE_DICTIONARY:
		keypath.remove_at(0)
		_set_json_path(dict[current], keypath, value) # recursion happens here
		return
	elif typeof(dict[current]) == TYPE_ARRAY:
		keypath.remove_at(0)
		_set_json_path(dict[current], keypath, value) # recursion happens here
		return
	else:
		dict[current] = value
		return


func _on_app_toggle_app_started():
	pass # Replace with function body.


# func _notification(what):
# 	if what == NOTIFICATION_WM_CLOSE_REQUEST:
# 		var ready_to_close := true

# 		for app_toggle in get_node(app_toggle_container).get_children():
# 			if app_toggle.app_process_id != -1:
				