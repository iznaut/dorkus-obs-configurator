extends Control

signal main_ready

const ASSISTANT_SCENE := preload("res://src/assistant/dorkus_assistant.tscn")
const BUG_REPORT = preload("res://src/windows/bug_report_window.tscn")

@export var steam_button : Control

var assistant : Control
var bug_form : PopupPanel

@onready var obs_helper = $OBSHelper
@onready var button_grid = $GridContainer


func _ready():
	if not Utility.does_config_exist():
		var content = FileAccess.get_file_as_string("res://config_template.ini")
		var new_config = FileAccess.open(Utility.get_config_path(), FileAccess.WRITE)
		new_config.store_string(content)
		new_config.close()

	# DisplayServer.window_set_title("Dorkus Assistant")
	# size = Vector2i(640,480)
	get_window().transparent_bg = true

	fix_sources()
	get_tree().set_auto_accept_quit(false)

	create_assistant()

	bug_form = BUG_REPORT.instantiate()
	get_window().add_child.call_deferred(bug_form)
	bug_form.about_to_popup.connect(assistant._on_bug_report_popup)
	bug_form.popup_hide.connect(assistant._on_bug_report_hide)
	bug_form.get_node("Control").user_typed.connect(assistant._on_bug_report_user_typed)
	bug_form.get_node("Control").user_submitted.connect(_on_bug_report_user_submitted)

	for menu_button in button_grid.get_children():
		menu_button.button_pressed.connect(_on_menu_button_pressed)


func create_assistant():
	# create window for dorkus and save reference to his node
	var assistant_window = Window.new()
	assistant = ASSISTANT_SCENE.instantiate()

	# resize window to fit dorkus and add him to it
	assistant_window.size = assistant.size
	assistant_window.add_child(assistant, true)
	add_child(assistant_window)
	
	# TODO - find less bad way of aligning to taskbar/screen edge
	var res := DisplayServer.screen_get_size()
	@warning_ignore("integer_division")
	assistant_window.position = res - assistant_window.size + Vector2i(0, res.y / 2 + 5)

	# override a bunch of options for assistant window
	assistant_window.unfocusable = true
	assistant_window.always_on_top = true
	assistant_window.transparent = true
	assistant_window.transparent_bg = true
	assistant_window.borderless = true
	assistant_window.exclusive = true
	assistant_window.popup_window = true
	assistant_window.show()

	# connect signals
	obs_helper.replay_buffer_saved.connect(assistant._on_replay_buffer_saved)


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
				

func _on_bug_report_button_pressed():
	var favro_email = Utility.get_user_config("Auth", "FavroEmail")
	var favro_token = Utility.get_user_config("Auth", "FavroToken")
	
	if favro_email == "" or favro_token == "":
		OS.shell_open(Utility.get_config_path())
	else:
		bug_form.popup()


func _on_open_favro_button_pressed():
	var favro_org_id = Utility.get_user_config("Auth", "FavroOrgId")
	
	if favro_org_id == "":
		OS.shell_open(Utility.get_config_path())
	else:
		OS.shell_open(Config.favro_url + "/" + Utility.get_user_config("Auth", "FavroOrgId"))


func _on_bug_report_user_submitted():
	bug_form.hide()
	assistant.notification_requested.emit(assistant.AnimState.NOTEPAD_BUG)


func _on_steam_run_button_pressed():
	var steam_app_id = Utility.get_user_config("SteamConfig", "AppID")

	if steam_app_id == "":
		OS.shell_open(Utility.get_config_path())
	else:
		OS.shell_open("steam://rungameid/" + steam_app_id)
		steam_button.button.disabled = true


func _on_menu_button_pressed(label : String):
	match label:
		"Launch Game":
			_on_steam_run_button_pressed()
		"Show Recordings":
			obs_helper._on_recordings_button_pressed()
		"Submit Task":
			_on_bug_report_button_pressed()
		"Open Favro":
			_on_open_favro_button_pressed()
