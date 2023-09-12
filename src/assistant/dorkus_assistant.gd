extends Control


enum MenuItem {
	START_STOP_RECORDING = 0,
	SAVE_REPLAY = 1,
	OPEN_RECORDING_FOLDER = 2,
	FRAMEIO_UPLOAD = 4,
	SYNC_WITH_GAME = 5,
	CLOSE = 7,
}

const STATE_DIR = "res://src/assistant/states/"
const OBS_OPTION_BOOLS = {
	MenuItem.FRAMEIO_UPLOAD: "upload_on_recording_saved",
	MenuItem.SYNC_WITH_GAME: "sync_with_unreal",
}

@export var default_idle_frame : Texture2D
@export var default_notification_frame : Texture2D

var current_state_data : AssistState
var current_frame_index : int
var record_state_change_requested : bool

@onready var dorkus = $CharacterGroup/Dorkus
@onready var notif_bubble = $CharacterGroup/SpeechBubble
@onready var timer = $Timer
@onready var menu = $PopupMenu


func _ready():
	var parent_window = get_window()
	
	@warning_ignore("integer_division")
	parent_window.position = DisplayServer.screen_get_usable_rect().end - parent_window.size
	parent_window.transparent_bg = true

	SignalBus.state_updated.connect(_update_state)
	SignalBus.state_updated.emit("starting_up")

	# await SignalBus.obs_opened
	# for id in OBS_OPTION_BOOLS.keys():
	# 	var index = menu.get_item_index(id)
	# 	print(index)
	# 	print(OBS_OPTION_BOOLS[id])
	# 	SignalBus.config_setting_updated.emit(OBS_OPTION_BOOLS[id], menu.is_item_checked(index))


func _update_state(new_state_name : String):
	if new_state_name == "idle":
		dorkus.texture = default_idle_frame
		current_state_data = null
		return
	if new_state_name == "obs_connected":
		menu.set_item_disabled(MenuItem.START_STOP_RECORDING, false)
		menu.set_item_disabled(MenuItem.SAVE_REPLAY, false)
		menu.set_item_disabled(MenuItem.OPEN_RECORDING_FOLDER, false)
	if new_state_name == "obs_recording_started":
		menu.set_item_text(
			MenuItem.START_STOP_RECORDING,
			"Stop Recording"
		)
	if new_state_name == "obs_recording_stopping":
		menu.set_item_text(
			MenuItem.START_STOP_RECORDING,
			"Start Recording"
		)

	current_state_data = load(STATE_DIR.path_join("%s.tres" % new_state_name))

	if current_state_data == null:
		dorkus.texture = default_notification_frame
		return

	if current_state_data.has_frames():
		current_frame_index = 0
		dorkus.texture = current_state_data.frames[current_frame_index]
	else:
		dorkus.texture = default_notification_frame

	if current_state_data.message:
		notif_bubble.show()
		notif_bubble.find_child("Label").text = current_state_data.message

	if current_state_data.is_animated():
		timer.wait_time = current_state_data.delay

	# wait a bit before clearing notification
	if current_state_data.timeout > 0:
		await get_tree().create_timer(current_state_data.timeout).timeout
		notif_bubble.hide()

		# if not a repeating animation, return to idle
		# TODO these are non-blocking so there can be conflicts with timers going off
		if current_state_data == null or not current_state_data.is_animated():
			_update_state("idle")


func _on_timer_timeout():
	if current_state_data and current_state_data.is_animated():
		current_frame_index += 1
		if current_frame_index >= current_state_data.frames.size():
			current_frame_index = 0

		dorkus.texture = current_state_data.frames[current_frame_index]

	timer.start()


func _on_gui_input(event:InputEvent):
	if event is InputEventMouseButton and event.button_index == 2 and event.pressed:
		# about_to_popup() signal doesn't seem to work?
		_on_popup_menu_about_to_popup()
		menu.visible = !menu.visible


func _on_popup_menu_id_pressed(id:int):
	match id:
		MenuItem.START_STOP_RECORDING:
			SignalBus.obs_command_requested.emit("ToggleRecord")
		MenuItem.SAVE_REPLAY:
			SignalBus.obs_command_requested.emit("SaveReplayBuffer")
		MenuItem.OPEN_RECORDING_FOLDER:
			SignalBus.obs_command_requested.emit("GetProfileParameter", {"parameterCategory": "AdvOut","parameterName": "RecFilePath"})
		MenuItem.CLOSE:
			get_window().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		_:
			var index = menu.get_item_index(id)
			if menu.is_item_checkable(index):
				menu.toggle_item_checked(index)
				SignalBus.config_setting_updated.emit(OBS_OPTION_BOOLS[index], menu.is_item_checked(index))


func _on_popup_menu_about_to_popup():
	var user_frameio_root_asset_id = Utility.get_user_config("Frameio", "RootAssetID")
	var user_frameio_token = Utility.get_user_config("Frameio", "Token")

	if user_frameio_root_asset_id != "":
		# TODO would rather use signals probably? but hard ref is working
		# SignalBus.config_setting_updated.emit("frameio_root_asset_id", user_frameio_root_asset_id)
		%OBSHelper.frameio_root_asset_id = user_frameio_root_asset_id
	if user_frameio_token != "":
		# SignalBus.config_setting_updated.emit("frameio_token", user_frameio_token)
		%OBSHelper.frameio_token = user_frameio_token

	menu.set_item_disabled(
		MenuItem.FRAMEIO_UPLOAD,
		%OBSHelper.frameio_token == ""
	)
