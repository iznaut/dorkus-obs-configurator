extends PopupMenu


enum {
	START_STOP_RECORDING = 0,
	SAVE_REPLAY = 1,
	TAKE_SCREENSHOT = 8,
	OPEN_RECORDING_FOLDER = 2,
	FRAMEIO_UPLOAD = 4,
	SYNC_WITH_GAME = 5,
	CLOSE = 7,
}

const OBS_COMMANDS = {
	START_STOP_RECORDING: "ToggleRecord",
	SAVE_REPLAY: "SaveReplayBuffer",
	TAKE_SCREENSHOT: [
		"SaveSourceScreenshot",
		{
			"sourceName": "Game Capture",
			"imageFormat": "png",
			"imageFilePath": "D:/Screenshots/test/test.png"
		}
	],
	OPEN_RECORDING_FOLDER: [
		"GetProfileParameter",
		{
			"parameterCategory": "AdvOut",
			"parameterName": "RecFilePath"
		}
	],
}
const OBS_OPTIONS = {
	FRAMEIO_UPLOAD: "upload_on_recording_saved",
	SYNC_WITH_GAME: "sync_with_unreal",
}

var obs_helper


func _init():
	id_pressed.connect(_on_id_pressed)
	about_to_popup.connect(_on_about_to_popup)


func _on_assistant_state_updated(new_state_name : String):
	match new_state_name:
		"obs_connected":
			set_item_disabled(START_STOP_RECORDING, false)
			set_item_disabled(SAVE_REPLAY, false)
			set_item_disabled(OPEN_RECORDING_FOLDER, false)
		"obs_recording":
			set_item_text(
				START_STOP_RECORDING,
				"Stop Recording"
			)
		"obs_recording_stopping":
			set_item_text(
				START_STOP_RECORDING,
				"Start Recording"
			)


func _on_id_pressed(id:int):
	if id in OBS_COMMANDS.keys():
		var command = OBS_COMMANDS[id]
		var params = null

		if command is Array:
			params = command[1]
			command = command[0]

		obs_helper.obs_command_requested.emit(command, params if params != null else {})

	if id in OBS_OPTIONS.keys():
		var index = get_item_index(id)

		if is_item_checkable(index):
			toggle_item_checked(index)
			obs_helper.config_setting_updated.emit(OBS_OPTIONS[id], is_item_checked(index))
	
	if id == CLOSE:
			get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _on_about_to_popup():
	# always_on_top = true
	# position = get_parent().get_window().position

	var user_frameio_root_asset_id = Utility.get_user_config("Frameio", "RootAssetID")
	var user_frameio_token = Utility.get_user_config("Frameio", "Token")

	if user_frameio_root_asset_id != "":
		# TODO would rather use signals probably? but hard ref is working
		# SignalBus.config_setting_updated.emit("frameio_root_asset_id", user_frameio_root_asset_id)
		obs_helper.frameio_root_asset_id = user_frameio_root_asset_id
	if user_frameio_token != "":
		# SignalBus.config_setting_updated.emit("frameio_token", user_frameio_token)
		obs_helper.frameio_token = user_frameio_token

	# disable frame.io upload if no token defined
	set_item_disabled(
		FRAMEIO_UPLOAD,
		obs_helper.frameio_token == ""
	)

	# refresh checkboxes to match obs bools
	for id in OBS_OPTIONS.keys():
		var index = get_item_index(id)
		set_item_checked(
			index,
			obs_helper.get(OBS_OPTIONS[id])
		)


func _on_close_requested():
	queue_free()
