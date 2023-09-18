extends PopupMenu


signal menu_initialized(popup)

# TODO id vs index is annoying to manage
# these are IDs
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
const CONFIG_OPTIONS = {
	FRAMEIO_UPLOAD: "upload_enabled",
	SYNC_WITH_GAME: "game_sync_enabled",
}

var config : Node


func _init():
	OBSHelper.state_updated.connect(_on_obs_state_updated)
	id_pressed.connect(_on_id_pressed)
	about_to_popup.connect(_on_about_to_popup)


func _on_obs_state_updated(new_state_name : String):
	match new_state_name:
		"obs_connected":
			set_item_disabled(get_item_index(START_STOP_RECORDING), false)
			set_item_disabled(get_item_index(SAVE_REPLAY), false)
			set_item_disabled(get_item_index(TAKE_SCREENSHOT), false)
			set_item_disabled(get_item_index(OPEN_RECORDING_FOLDER), false)
		"obs_recording":
			set_item_text(
				get_item_index(START_STOP_RECORDING),
				"Stop Recording"
			)
		"obs_recording_stopping":
			set_item_text(
				get_item_index(START_STOP_RECORDING),
				"Start Recording"
			)


func _on_id_pressed(id:int):
	if id in OBS_COMMANDS.keys():
		var command = OBS_COMMANDS[id]
		var params = null

		if command is Array:
			params = command[1]
			command = command[0]

		OBSHelper.send_command(command, params if params != null else {})

	if id in CONFIG_OPTIONS.keys():
		var index = get_item_index(id)

		if is_item_checkable(index):
			toggle_item_checked(index)
			config.set(CONFIG_OPTIONS[id], is_item_checked(index))
	
	if id == CLOSE:
			get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _on_about_to_popup():
	# refresh checkboxes to match config bools
	for id in CONFIG_OPTIONS.keys():
		var index = get_item_index(id)
		set_item_checked(
			index,
			config.get(CONFIG_OPTIONS[id])
		)
	
	# disable frame.io upload if no token defined
	set_item_disabled(
		get_item_index(FRAMEIO_UPLOAD),
		not Utility.get_frameio_config() is Array
	)
	
	# TODO look into dynamic resolution setting - must happen with record/replay buffer off
	# OBSHelper.send_command(
	# 	"SetVideoSettings",
	# 	{
	# 		"baseWidth": DisplayServer.screen_get_size().x,
	# 		"baseHeight": DisplayServer.screen_get_size().y
	# 	}
	# )
