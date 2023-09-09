extends "res://addons/obs-websocket-gd/obs_websocket.gd"


signal recording_saved(filepath)
signal obs_opened(pid)

const SOURCE_REMAPS = {
		"image_source": {
			"file": "dorkus-white.png"
		},
		"input-overlay": {
			"io.overlay_image": "game-pad.png",
			"io.layout_file": "game-pad.json",
		},
	}

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
var output_state : String = ""
var obs_process_id : int


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

	Utility.write_json(
		scene_json_filepath,
		Utility.replace_filepaths_in_json(
			obs_root,
			original_contents,
			SOURCE_REMAPS
		)
	)

	# start OBS and connect to websocket server
	assert(FileAccess.file_exists(exe_filepath), "Could not find OBS executable at expected path")
	
	_start_obs()
	_request_connection()


func _start_obs() -> void:
	var output = []
	var params = [
		"$process = Start-Process %s -WorkingDirectory %s -PassThru;" % [exe_filepath, exe_filepath.get_base_dir()],
		"return $process.Id"
	]

	var obs_open_thread = Thread.new()
	obs_open_thread.start(
		func():
			OS.execute("PowerShell.exe", params, output)
			return output[0].replace("\\r\\n", "") as int
	)

	obs_process_id = obs_open_thread.wait_to_finish()


func _request_connection() -> void:
	connection_authenticated.connect(
		func():
			send_command("StartReplayBuffer")

			# let other nodes know we've connected
			SignalBus.state_updated.emit("obs_connected")

			# accept commands sent to signal bus
			SignalBus.obs_command_requested.connect(send_command)

			if helper_to_sync:
				helper_to_sync.request_connection()
	)
	data_received.connect(_on_obs_data_recieved)

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
	establish_connection()


func _on_obs_data_recieved(data):
	print(data)
	
	if data is RequestResponse:
		var request_type = data["request_type"]
		var response_data = data["response_data"]
		
		match request_type:
			"GetProfileParameter":
				OS.shell_open(response_data.parameterValue)
	elif data is Event:
		var event_type = data["event_type"]
		var event_data = data["event_data"]

		output_state = event_data.outputState
		
		# TODO cleanup - map obs states and dorkus states
		match event_type:
			"RecordStateChanged":
				match event_data.outputState:
					"OBS_WEBSOCKET_OUTPUT_STARTED":
						SignalBus.state_updated.emit("obs_recording_started")
					"OBS_WEBSOCKET_OUTPUT_STOPPING":
						SignalBus.state_updated.emit("obs_recording_stopping")
					"OBS_WEBSOCKET_OUTPUT_STOPPED":
						var new_recording_filepath = event_data.outputPath
						
						SignalBus.state_updated.emit("obs_recording_saved")
						await get_tree().create_timer(1).timeout

						if upload_on_recording_saved:
							var is_upload_successful = _upload_file_to_frameio(new_recording_filepath)
							SignalBus.state_updated.emit("frameio_upload_%s" % "succeeded" if is_upload_successful else "failed")
							await get_tree().create_timer(1).timeout

						if close_on_recording_saved:
							get_window().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)

						recording_saved.emit(new_recording_filepath)
			"ReplayBufferSaved":
				var _new_buffer_filepath = event_data.savedReplayPath
				SignalBus.state_updated.emit("obs_recording_saved")


func _upload_file_to_frameio(filepath) -> bool:
	var output = []
	var params = [
		Utility.get_user_config("Frameio", "Token"),
		Utility.get_user_config("Frameio", "RootAssetID"),
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

	return result != null


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("obs close requested")
		# if app is running
		if obs_process_id != -1:
			if output_state == "OBS_WEBSOCKET_OUTPUT_STARTED":
				recording_saved.connect(
					func(_filepath):
						OS.kill(obs_process_id)

						get_tree().quit()
				)
				send_command("StopRecord")
				print("stopping record")
				return
			else:
				OS.kill(obs_process_id)

		get_tree().quit()
