extends "res://addons/obs-websocket-gd/obs_websocket.gd"


signal state_updated(new_state_name)
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

var close_on_recording_saved : bool
var obs_root = Utility.globalize_subpath("obs")
var exe_filepath : String = obs_root.path_join("bin/64bit/obs64.exe")
var config_paths : Dictionary = {
	"profile": obs_root.path_join("config/obs-studio/basic/profiles/Default/basic.ini"),
	"scene": obs_root.path_join("config/obs-studio/basic/scenes/Unreal_Engine.json"),
}
var last_known_record_state
var obs_process_id : int
var scene_item_list : Dictionary


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
	
	# start or attach to OBS process
	obs_process_id = Utility.execute_powershell(
		[
			obs_root.path_join("start_process.ps1"),
			exe_filepath
		]
	)
	_request_connection()


func _request_connection() -> void:
	connection_authenticated.connect(_on_connection_authenticated)
	data_received.connect(_on_obs_data_recieved)

	set_process(true)
	establish_connection()


func _on_connection_authenticated():
	send_command("StartReplayBuffer")
	send_command("GetSceneItemList", {"sceneName": "Playtest"})

	# let other nodes know we've connected
	state_updated.emit("obs_connected")

	# accept commands sent to signal bus
	obs_command_requested.connect(send_command)


func _on_obs_data_recieved(data):
	print(data)
	if data is RequestResponse:
		var request_type = data["request_type"]
		var response_data = data["response_data"]
		
		match request_type:
			"GetProfileParameter":
				OS.shell_open(response_data.parameterValue)
			"GetSceneItemList":
				for item in response_data.sceneItems:
					scene_item_list[item.sourceName] = item.sceneItemId
	elif data is Event:
		var event_type = data["event_type"]
		var event_data = data["event_data"]
		
		# TODO cleanup - map obs states and dorkus states
		match event_type:
			"RecordStateChanged":
				last_known_record_state = event_data.outputState

				match last_known_record_state:
					"OBS_WEBSOCKET_OUTPUT_STARTED":
						state_updated.emit("obs_recording")
					"OBS_WEBSOCKET_OUTPUT_STOPPING":
						state_updated.emit("obs_recording_stopping")
					"OBS_WEBSOCKET_OUTPUT_STOPPED":
						var new_recording_filepath = event_data.outputPath
						
						state_updated.emit("obs_recording_saved")
						await get_tree().create_timer(1).timeout

						recording_saved.emit(new_recording_filepath)
			"ReplayBufferSaved":
				var _new_buffer_filepath = event_data.savedReplayPath
				state_updated.emit("obs_replay_saved")


func set_scene_item_enabled(item_name : String, enabled : bool):
	send_command(
		"SetSceneItemEnabled",
		{
			"sceneName": "Playtest",
			"sceneItemId": scene_item_list[item_name],
			"sceneItemEnabled": enabled
		}
	)


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
