extends WebsocketHelper


signal recording_saved(filepath)

const OBS_WEBSOCKET: GDScript = preload("res://addons/obs-websocket-gd/obs_websocket.gd")

@export_category("Auto-Record")
@export var helper_to_sync : WebsocketHelper
@export var close_on_recording_saved : bool

@export_category("Frame.io Integration")
@export var upload_on_recording_saved : bool

var exe_filepath : String = Utility.get_working_dir().path_join("obs/bin/64bit/obs64.exe")
var config_paths : Dictionary = {
	"profile": "res://obs/config/obs-studio/basic/profiles/Default/basic.ini",
	"scenes": "res://obs/config/obs-studio/basic/scenes/Unreal_Engine.json"
}
var source_remaps = {
		"image_source": {
			"file": "dorkus-white.png"
		},
		"input-overlay": {
			"io.overlay_image": "game-pad.png",
			"io.layout_file": "game-pad.json",
		},
	}
var output_state : String = ""
var is_recording : bool:
	get:
		return not output_state in ["OBS_WEBSOCKET_OUTPUT_STOPPED", ""]


func _ready():
	super()

	if not FileAccess.file_exists(exe_filepath):
		%ProgressBar.start_download()

		await %ProgressBar.download_complete
	
	# workaround for OBS not allowing relative source filepaths
	var scenes_json_filepath = config_paths["scenes"]
	var original_contents : Variant = Utility.read_json(scenes_json_filepath)
	Utility.write_json(scenes_json_filepath, Utility.replace_filepaths_in_json(Utility.get_working_dir().path_join("obs"), original_contents, source_remaps))

	# # start OBS and connect to websocket server
	assert(FileAccess.file_exists(exe_filepath), "Could not find OBS executable at expected path")
	app_process_id = Utility.start_process(exe_filepath)
	request_connection()


func request_connection() -> void:
	socket = OBS_WEBSOCKET.new()
	add_child(socket)

	# bind plugin signals to Helper class signals
	socket.connection_authenticated.connect(
		func():
			send_command("GetProfileParameter", {"parameterCategory": "AdvOut","parameterName": "RecFilePath"})
			send_command("StartReplayBuffer")
			connection_opened.emit()
			SignalBus.state_update_requested.emit(AssistState.AppState.OBS_CONNECTED)

			if helper_to_sync:
				helper_to_sync.request_connection()
	)
	socket.connection_closed.connect(
		func():
			connection_closed.emit()
	)
	socket.data_received.connect(
		func(data):
			data = JSON.parse_string(data.get_as_json()).d

			_on_obs_data_recieved(data)

			data_received.emit(data)
	)

	# bind sync'd helper for auto recording start/stop
	helper_to_sync.connection_opened.connect(
		func():
			send_command("StartRecord")
			SignalBus.state_update_requested.emit(AssistState.AppState.OBS_RECORDING_STARTED)
	)
	helper_to_sync.connection_closed.connect(
		func():
			send_command("StopRecord")
			SignalBus.state_update_requested.emit(AssistState.AppState.OBS_RECORDING_STOPPED)
	)

	set_process(true)
	socket.establish_connection()


# pass through to plugin function
func send_command(command: String, data: Dictionary = {}) -> void:
	assert(socket != null, "OBS Websocket not initialized")
	socket.send_command(command, data)


func _on_obs_data_recieved(data):
	# handle request responses
	# if data.has("requestType"):
		# print(data.requestType)

	# handle event messages
	if data.has("eventType"):
		var type = data.eventType
		var record_state_just_changed = false
		var new_recording_filepath = ""

		if type == "RecordStateChanged":
			output_state = data.eventData.outputState
			record_state_just_changed = true

		if type == "ReplayBufferSaved":
			new_recording_filepath = data.eventData.savedReplayPath

		if record_state_just_changed and output_state == "OBS_WEBSOCKET_OUTPUT_STOPPED":
			new_recording_filepath = data.eventData.outputPath
		
		if new_recording_filepath != "":
			if upload_on_recording_saved:
				Utility.upload_file_to_frameio(new_recording_filepath)

			recording_saved.emit(new_recording_filepath)

			if close_on_recording_saved:
				get_window().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("obs close requested")
		# if app is running
		if app_process_id != -1:
			if is_recording:
				recording_saved.connect(
					func(_filepath):
						OS.kill(app_process_id)

						get_tree().quit()
				)
				send_command("StopRecord")
				print("stopping record")
				return
			else:
				OS.kill(app_process_id)

		get_tree().quit()
