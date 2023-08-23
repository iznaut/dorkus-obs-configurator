extends WebsocketHelper


signal recording_saved(filepath)

const ObsWebsocket: GDScript = preload("res://addons/obs-websocket-gd/obs_websocket.gd")

@export var helper_to_sync : WebsocketHelper
@export var frame_io_autoupload : bool

var output_state : String = ""


func _ready():
	super()
	fix_sources()

	assert(FileAccess.file_exists(Config.obs_exe), "Could not find OBS executable at expected path")

	if app_process_id == -1:
		app_process_id = Utility.start_process(Config.obs_exe)

		request_connection()


func fix_sources():
	var json_path = Config.obs_scene

	var original_contents : Variant = Utility.read_json(json_path)
	Utility.write_json(json_path, Utility.replace_filepaths_in_json(original_contents, Config.source_remaps))


func request_connection() -> void:
	socket = ObsWebsocket.new()
	add_child(socket)

	# bind plugin signals to Helper class signals
	socket.connection_authenticated.connect(
		func():
			send_command("GetProfileParameter", {"parameterCategory": "AdvOut","parameterName": "RecFilePath"})
			send_command("StartReplayBuffer")
			connection_opened.emit()

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
	)
	helper_to_sync.connection_closed.connect(
		func():
			send_command("StopRecord")
	)

	set_process(true)
	socket.establish_connection()


# pass through to plugin function
func send_command(command: String, data: Dictionary = {}) -> void:
	assert(socket != null, "OBS Websocket not initialized")
	socket.send_command(command, data)


func _on_obs_data_recieved(data):
	# handle request responses
	if data.has("requestType"):
		print(data.requestType)

	# handle event messages
	if data.has("eventType"):
		var type = data.eventType
		var record_state_just_changed = false
		var new_recording_filepath = ""

		print(type)

		if type == "RecordStateChanged":
			output_state = data.eventData.outputState
			record_state_just_changed = true

		if type == "ReplayBufferSaved":
			new_recording_filepath = data.eventData.savedReplayPath

		if record_state_just_changed and output_state == "OBS_WEBSOCKET_OUTPUT_STOPPED":
			new_recording_filepath = data.eventData.outputPath
		
		if new_recording_filepath != "":
			if frame_io_autoupload:
				Utility.upload_file_to_frameio(new_recording_filepath)

			recording_saved.emit(new_recording_filepath)


func _on_close_request():
	send_command("StopRecord")
