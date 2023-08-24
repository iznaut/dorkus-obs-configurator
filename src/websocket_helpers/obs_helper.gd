extends WebsocketHelper


signal recording_saved(filepath)

const ObsWebsocket: GDScript = preload("res://addons/obs-websocket-gd/obs_websocket.gd")

@export_category("Auto-Record")
@export var helper_to_sync : WebsocketHelper

@export_category("Frame.io Integration")
@export var upload_on_recording_saved : bool

var obs_root : String :
	get:
		var target = "dorkus-obs"

		# use /build if running in editor
		if OS.has_feature("editor"):
			target = "build".path_join(target)

		return Utility.get_working_dir().path_join(target)
var relative_paths : Dictionary = {
	"executable": "bin/64bit/obs64.exe",
	"profile": "config/obs-studio/basic/profiles/Default/basic.ini",
	"scenes": "config/obs-studio/basic/scenes/Unreal_Engine.json"
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
var ready_to_close : bool:
	get:
		return output_state in ["OBS_WEBSOCKET_OUTPUT_STOPPED", ""]


func _ready():
	super()
	
	# workaround for OBS not allowing relative source filepaths
	var scenes_json_filepath = obs_root.path_join(relative_paths["scenes"])
	var original_contents : Variant = Utility.read_json(scenes_json_filepath)
	Utility.write_json(scenes_json_filepath, Utility.replace_filepaths_in_json(obs_root, original_contents, source_remaps))

	# start OBS and connect to websocket server
	var exe_filepath = obs_root.path_join(relative_paths["executable"])
	assert(FileAccess.file_exists(exe_filepath), "Could not find OBS executable at expected path")
	app_process_id = Utility.start_process(exe_filepath)
	request_connection()


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


func _on_close_request():
	send_command("StopRecord")
