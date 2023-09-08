extends WebsocketHelper


signal recording_saved(filepath)

const OBS_WEBSOCKET: GDScript = preload("res://addons/obs-websocket-gd/obs_websocket.gd")

@export_category("Auto-Record")
@export var helper_to_sync : WebsocketHelper
@export var close_on_recording_saved : bool

@export_category("Frame.io Integration")
@export var upload_on_recording_saved : bool

var obs_root = Utility.get_working_dir().path_join("obs")
var exe_filepath : String = obs_root.path_join("bin/64bit/obs64.exe")
var config_paths : Dictionary = {
	"profile": obs_root.path_join("config/obs-studio/basic/profiles/Default/basic.ini"),
	"scene": obs_root.path_join("config/obs-studio/basic/scenes/Unreal_Engine.json"),
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
		return output_state == "OBS_WEBSOCKET_OUTPUT_STARTED"


func _ready():
	super()

	# disable normal quit behavior so we can safely handle app close first
	get_tree().set_auto_accept_quit(false)

	# create user config file if missing
	if not FileAccess.file_exists(Utility.get_user_config_path()):
		var content = FileAccess.get_file_as_string("res://support/config_template.ini")
		var new_file = FileAccess.open(Utility.get_working_dir().path_join("config.ini"), FileAccess.WRITE)
		new_file.store_string(content)
		new_file.close()

	# copy default obs config if missing
	if not DirAccess.dir_exists_absolute(obs_root):
		Utility.copy_directory_recursively("res://support/obs/", obs_root)

	# download obs if missing
	if not FileAccess.file_exists(exe_filepath):
		%ProgressBar.start_download()

		await %ProgressBar.download_complete
	
	# workaround for OBS not allowing relative source filepaths
	var scene_json_filepath = config_paths["scene"]
	var original_contents : Variant = Utility.read_json(scene_json_filepath)
	Utility.write_json(scene_json_filepath, Utility.replace_filepaths_in_json(obs_root, original_contents, source_remaps))

	# start OBS and connect to websocket server
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
			SignalBus.state_update_requested.emit("obs_connected")
			SignalBus.obs_command_requested.connect(send_command)
			SignalBus.obs_state_requested.connect(
				func():
					SignalBus.obs_state_reported.emit(is_recording)
			)

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

			SignalBus.obs_state_reported.emit(is_recording)

			if output_state == "OBS_WEBSOCKET_OUTPUT_STARTED":
				SignalBus.state_update_requested.emit("obs_recording_started")
			if output_state == "OBS_WEBSOCKET_OUTPUT_STOPPED":
				SignalBus.state_update_requested.emit("obs_recording_stopped")

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
