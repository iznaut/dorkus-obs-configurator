extends Control

signal main_ready

const ASSISTANT_SCENE := preload("res://src/assistant/dorkus_assistant.tscn")
const BUG_REPORT = preload("res://src/windows/bug_report_window.tscn")

@export var steam_button : Control

var assistant : Control
var bug_form : PopupPanel
var unreal_helper

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

	create_assistant()

	bug_form = BUG_REPORT.instantiate()
	get_window().add_child.call_deferred(bug_form)
	bug_form.about_to_popup.connect(assistant._on_bug_report_popup)
	bug_form.popup_hide.connect(assistant._on_bug_report_hide)
	bug_form.get_node("Control").user_typed.connect(assistant._on_bug_report_user_typed)
	bug_form.get_node("Control").user_submitted.connect(_on_bug_report_user_submitted)

	for menu_button in button_grid.get_children():
		menu_button.button_pressed.connect(_on_menu_button_pressed)

	OBSHelper.connection_opened.connect(_on_obs_connected)


func create_assistant():
	# create window for dorkus and save reference to his node
	var assistant_window = Window.new()
	assistant = ASSISTANT_SCENE.instantiate()

	# resize window to fit dorkus and add him to it
	assistant_window.size = assistant.size
	assistant_window.add_child(assistant, true)
	add_child(assistant_window)

	# # connect signals
	# obs_helper.replay_buffer_saved.connect(assistant._on_replay_buffer_saved)


func _on_obs_connected():
	print("obs connected")
	UnrealHelper.connection_opened.connect(_on_unreal_connected)
	UnrealHelper.connection_closed.connect(_on_unreal_disconnected)
	UnrealHelper.request_connection()
	$Quit.disabled = false

	OBSHelper.recording_saved.connect(_on_obs_recording_saved)


func _on_unreal_connected():
	print("unreal connected, recording started")
	OBSHelper.obs_websocket.send_command("StartRecord")


func _on_unreal_disconnected():
	print("unreal disconnected, stopping record")
	OBSHelper.obs_websocket.send_command("StopRecord")


func _on_obs_recording_saved(filepath):
	print(Utility.upload_file_to_frameio(filepath))


func _on_app_toggle_app_started():
	pass # Replace with function body.
				

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
			OBSHelper._on_recordings_button_pressed()
		"Submit Task":
			_on_bug_report_button_pressed()
		"Open Favro":
			_on_open_favro_button_pressed()
