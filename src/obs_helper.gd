extends "res://addons/obs-websocket-gd/obs_websocket.gd"


signal state_update_requested(new_state_name)

signal config_setting_requested(var_name)
signal config_setting_updated(var_name, new_value)

signal obs_command_requested(command, data)

signal recording_saved(filepath)

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
@export var sync_with_unreal : bool:
	set(new_value):
		if not is_inside_tree(): await ready
		_bind_game_helper(!new_value)
		sync_with_unreal = new_value
var helper_to_sync : WebsocketHelper
var start_record_func = func(): send_command("StartRecord")
var stop_record_func = func(): send_command("StopRecord")

@export_category("Frame.io Integration")
@export var frameio_root_asset_id : String
@export var frameio_token : String

var close_on_recording_saved : bool
var upload_on_recording_saved : bool

var obs_root = Utility.globalize_subpath("obs")
var exe_filepath : String = obs_root.path_join("bin/64bit/obs64.exe")
var config_paths : Dictionary = {
	"profile": obs_root.path_join("config/obs-studio/basic/profiles/Default/basic.ini"),
	"scene": obs_root.path_join("config/obs-studio/basic/scenes/Unreal_Engine.json"),
}
var last_known_record_state
var obs_process_id : int


func _ready():
	super()

	# disable normal quit behavior so we can safely handle app close first
	get_tree().set_auto_accept_quit(false)

	# create user config file if missing
	if not FileAccess.file_exists(Utility.get_user_config_path()):
		var content = FileAccess.get_file_as_string("res://support/config_template.ini")
		var new_file = FileAccess.open(
			Utility.globalize_subpath("config.ini"),
			FileAccess.WRITE
		)
		new_file.store_string(content)
		new_file.close()

	# copy default obs config if missing
	if not DirAccess.dir_exists_absolute(obs_root):
		Utility.copy_directory_recursively("res://support/obs/", obs_root)

	# download obs if missing
	# TODO make this a signal request
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

	config_setting_updated.connect(
		func(var_name, new_value):
			set(var_name, new_value)
	)
	config_setting_requested.connect(get)
	
	# start or attach to OBS process
	obs_process_id = Utility.execute_powershell(
		[
			obs_root.path_join("start_process.ps1"),
			exe_filepath
		]
	)
	_request_connection()


func _request_connection() -> void:
	connection_authenticated.connect(
		func():
			send_command("StartReplayBuffer")

			# let other nodes know we've connected
			state_update_requested.emit("obs_connected")

			# accept commands sent to signal bus
			obs_command_requested.connect(send_command)
	)
	data_received.connect(_on_obs_data_recieved)

	set_process(true)
	establish_connection()


func _bind_game_helper(unbind = false):
	if unbind:
		helper_to_sync.connection_opened.disconnect(start_record_func)
		helper_to_sync.connection_closed.disconnect(stop_record_func)

		helper_to_sync = null
	else:
		helper_to_sync = %UnrealHelper

		# bind sync'd helper for auto recording start/stop
		helper_to_sync.connection_opened.connect(start_record_func)
		helper_to_sync.connection_closed.connect(stop_record_func)

		helper_to_sync.request_connection()


func _on_obs_data_recieved(data):
	if data is RequestResponse:
		var request_type = data["request_type"]
		var response_data = data["response_data"]
		
		match request_type:
			"GetProfileParameter":
				OS.shell_open(response_data.parameterValue)
	elif data is Event:
		var event_type = data["event_type"]
		var event_data = data["event_data"]
		
		# TODO cleanup - map obs states and dorkus states
		match event_type:
			"RecordStateChanged":
				last_known_record_state = event_data.outputState

				match last_known_record_state:
					"OBS_WEBSOCKET_OUTPUT_STARTED":
						state_update_requested.emit("obs_recording")
					"OBS_WEBSOCKET_OUTPUT_STOPPING":
						state_update_requested.emit("obs_recording_stopping")
					"OBS_WEBSOCKET_OUTPUT_STOPPED":
						var new_recording_filepath = event_data.outputPath
						
						state_update_requested.emit("obs_recording_saved")
						await get_tree().create_timer(1).timeout

						if upload_on_recording_saved:
							var is_upload_successful = _upload_file_to_frameio(new_recording_filepath)
							state_update_requested.emit("frameio_upload_%s" % ("succeeded" if is_upload_successful else "failed"))
							await get_tree().create_timer(1).timeout

						if close_on_recording_saved:
							get_window().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)

						recording_saved.emit(new_recording_filepath)
			"ReplayBufferSaved":
				var _new_buffer_filepath = event_data.savedReplayPath
				state_update_requested.emit("obs_replay_saved")


func _upload_file_to_frameio(filepath) -> bool:
	var output = []
	var params = [
		frameio_token,
		frameio_root_asset_id,
		filepath,
	]

	# use precompiled script exe if shipping build
	var upload_script = obs_root.path_join("dist/windows/frameio_upload.exe")

	# if exe doesn't exist assume development and use original script
	if not FileAccess.file_exists(upload_script):
		upload_script = "python"
		params.push_front(
			Utility.globalize_subpath("obs/frameio_upload.py") if OS.has_feature("template") else ProjectSettings.globalize_path("res://support/obs/frameio_upload.py")
		)

	print("running %s" % upload_script)

	# TODO use utility call, is blocking
	OS.execute(upload_script, params, output, true, false)

	var result = JSON.parse_string(output[0])

	print(output)

	return result != null


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("obs close requested")
		# if app is running
		if obs_process_id != -1:
			send_command("GetRecordStatus")

			if last_known_record_state == "OBS_WEBSOCKET_OUTPUT_STARTED":
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