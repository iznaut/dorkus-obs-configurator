extends "res://addons/obs-websocket-gd/obs_websocket.gd"


signal connected
signal record_state_changed(is_recording)
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
const DOWNLOADER_SCENE = preload("res://src/assistant/obs_downloader.tscn")

var close_on_recording_saved : bool
var obs_root = Utility.globalize_subpath("obs")
var exe_filepath : String = obs_root.path_join("bin/64bit/obs64.exe")
var config_paths : Dictionary = {
	"profile": obs_root.path_join("config/obs-studio/basic/profiles/Default/basic.ini"),
	"scene": obs_root.path_join("config/obs-studio/basic/scenes/Unreal_Engine.json"),
}
var obs_process_id : int
var scene_item_list : Dictionary
var download_progress_bar : ProgressBar
var is_connected : bool
var is_recording : bool


func _ready():
	super()

	# disable normal quit behavior so we can safely handle app close first
	get_tree().set_auto_accept_quit(false)

	# copy default obs config if missing
	if not DirAccess.dir_exists_absolute(obs_root):
		Utility.copy_directory_recursively("res://support/obs/", obs_root)

	# download obs if missing
	if not FileAccess.file_exists(exe_filepath):
		var downloader = DOWNLOADER_SCENE.instantiate()
		add_child(downloader)

		downloader.start_download()

		await downloader.download_complete
	
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
	obs_process_id = Utility.os_execute_async(
		"Powershell.exe",
		[
			obs_root.path_join("start_process.ps1"),
			exe_filepath
		]
	)
	_request_connection()


func _request_connection() -> void:
	connection_authenticated.connect(_on_connection_authenticated)
	data_received.connect(_on_obs_data_recieved)
	record_state_changed.connect(
		func(output_active):
			is_recording = output_active
			StateMachine.state_updated.emit(StateMachine.IDLE) # is_recording checked in character.gd
	)

	set_process(true)
	establish_connection()


func _on_connection_authenticated():
	send_command("GetRecordStatus")
	send_command("GetSceneItemList", {"sceneName": "Playtest"})

	StateMachine.notification_updated.emit("Ready!", StateMachine.DEFAULT_NOTIFICATION_TIME)
	StateMachine.state_updated.emit(StateMachine.NOTIFICATION)


func _on_obs_data_recieved(data):
	print(data)
	if data is RequestResponse:
		var request_type = data["request_type"]
		var request_status = data["request_status"]
		var response_data = data["response_data"]
		
		match request_type:
			"GetProfileParameter":
				OS.shell_open(response_data.parameterValue)
				StateMachine.state_updated.emit(StateMachine.IDLE)
			"GetSceneItemList":
				for item in response_data.sceneItems:
					scene_item_list[item.sourceName] = item.sceneItemId
				
				# make sure we have the scene list before reporting connected
				connected.emit()
				is_connected = true
			"GetRecordStatus":
				record_state_changed.emit(response_data.outputActive)
			"SaveSourceScreenshot":
				var msg = "No game output detected!" if request_status.code == 702 else "Screenshot saved!"
				StateMachine.notification_updated.emit(msg, 2)
				StateMachine.state_updated.emit(StateMachine.NOTIFICATION)
	elif data is Event:
		var event_type = data["event_type"]
		var event_data = data["event_data"]
		
		# TODO cleanup - map obs states and dorkus states
		match event_type:
			"RecordStateChanged":
				match event_data.outputState:
					"OBS_WEBSOCKET_OUTPUT_STARTED":
						StateMachine.notification_updated.emit("Recording started!", StateMachine.DEFAULT_NOTIFICATION_TIME)
						record_state_changed.emit(true)
					"OBS_WEBSOCKET_OUTPUT_STOPPING":
						StateMachine.notification_updated.emit("Stopping...", 0)
						StateMachine.state_updated.emit(StateMachine.LOADING)
						record_state_changed.emit(false)
					"OBS_WEBSOCKET_OUTPUT_STOPPED":
						var new_recording_filepath = event_data.outputPath
						
						StateMachine.notification_updated.emit("Recording stopped!", StateMachine.DEFAULT_NOTIFICATION_TIME)
						StateMachine.state_updated.emit(StateMachine.NOTIFICATION)
						await get_tree().create_timer(1).timeout

						recording_saved.emit(new_recording_filepath)
			"ReplayBufferSaved":
				var _new_buffer_filepath = event_data.savedReplayPath
				StateMachine.notification_updated.emit("Replay saved!", StateMachine.DEFAULT_NOTIFICATION_TIME)
				StateMachine.state_updated.emit(StateMachine.NOTIFICATION)


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
			await record_state_changed

			if is_recording:
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
