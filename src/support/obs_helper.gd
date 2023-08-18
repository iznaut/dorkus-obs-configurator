extends CanvasLayer


signal app_started
signal connection_opened
signal replay_buffer_saved

const ObsWebsocket: GDScript = preload("res://addons/obs-websocket-gd/obs_websocket.gd")

@export var app_toggle : Button
@export var recording_list : VBoxContainer
@export var recording_list_item : PackedScene

var app_process_id : int = -1
var obs_websocket : Node
var default_recording_path : String
var user_recording_path : String
var waiting_to_close : bool = false
var output_state : String = ""


func _ready():
	# disable normal quit behavior so we can handle OBS shutdown too
	get_tree().set_auto_accept_quit(false)

	fix_sources()

	assert(FileAccess.file_exists(Config.obs_exe), "Could not find OBS executable at expected path")

	app_started.connect(connect_websocket)

	# user_recording_path = Utility.get_user_config("Cached", "RecFilePath")

	if app_process_id == -1:
		app_process_id = Utility.start_process(Config.obs_exe, "OBS")

		app_started.emit()


func _process(_delta):
	if waiting_to_close and (output_state == "OBS_WEBSOCKET_OUTPUT_STOPPED" or output_state == ""):
		OS.kill(app_process_id)
		get_tree().quit() # default behavior


func fix_sources():
	var json_path = Config.obs_scene

	var original_contents : Variant = Utility.read_json(json_path)
	Utility.write_json(json_path, Utility.replace_filepaths_in_json(original_contents, Config.source_remaps))


func connect_websocket() -> void:
	obs_websocket = ObsWebsocket.new()
	add_child(obs_websocket)

	obs_websocket.connection_closed.connect(_on_obs_disconnected)
	obs_websocket.data_received.connect(_on_obs_data_recieved)
	
	obs_websocket.establish_connection()
	
	await obs_websocket.connection_authenticated

	connection_opened.emit()
	
	obs_websocket.send_command("GetProfileParameter", {"parameterCategory": "AdvOut","parameterName": "RecFilePath"})


func _on_obs_data_recieved(data):
	data = JSON.parse_string(data.get_as_json()).d

	# print(data)

	if data.has("requestType"):
		# print(data.requestType)

		if data.requestType == "GetProfileParameter":
			default_recording_path = data.responseData.defaultParameterValue
			user_recording_path = data.responseData.parameterValue

			# Utility.set_user_config("Cached", "RecFilePath", user_recording_path)
	if data.has("eventType"):
		# print(data.eventType)

		if data.eventType == "ReplayBufferSaved":
			replay_buffer_saved.emit()

			var new_list_item = recording_list_item.instantiate()
			var new_filepath = data.eventData.savedReplayPath

			# var dir_access = DirAccess.new()
			var dir = DirAccess.open(user_recording_path)
			var renamed_filepath = new_filepath.replace("Replay", "NG3")
			dir.rename(new_filepath.get_file(), renamed_filepath.get_file())

			new_list_item.get_node("Link").uri = renamed_filepath
			new_list_item.get_node("Link").text = renamed_filepath.get_file()

			recording_list.add_child(new_list_item)

		if data.eventType == "RecordStateChanged":
			output_state = data.eventData.outputState


# func _on_obs_connecting():
# 	app_toggle.text = "%s is starting!" % app_toggle.app_title
# 	app_toggle.add_theme_color_override("font_color", Color.YELLOW)


func _on_obs_disconnected():
	obs_websocket.queue_free()


func _on_recordings_button_pressed():
	OS.shell_open(user_recording_path)


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if app_process_id != -1:
			OBSHelper.obs_websocket.send_command("StopRecord")

		waiting_to_close = true


func _on_connection_opened():
	obs_websocket.send_command("StartReplayBuffer")
