extends Control


enum MenuItem {
	START_STOP_RECORDING = 0,
	OPEN_RECORDING_FOLDER = 2,
	CLOSE = 4,
}

signal notification_requested(new_state : AssistState)

const STATE_DIR = "res://src/assistant/states/"

@export var default_idle_frame : Texture2D
@export var default_notification_frame : Texture2D

var current_state_data : AssistState
var current_frame_index : int
var record_state_change_requested : bool

@onready var dorkus = $CharacterGroup/Dorkus
@onready var notif_bubble = $CharacterGroup/SpeechBubble
@onready var timer = $Timer


func _ready():
	var parent_window = get_window()
	
	@warning_ignore("integer_division")
	parent_window.position = DisplayServer.screen_get_usable_rect().end - parent_window.size
	parent_window.transparent_bg = true

	SignalBus.state_updated.connect(_update_state)
	SignalBus.state_updated.emit("starting_up")


func _update_state(new_state_name : String):
	if new_state_name == "idle":
		dorkus.texture = default_idle_frame
		current_state_data = null
		return
	if new_state_name == "obs_connected":
		$PopupMenu.set_item_disabled(MenuItem.START_STOP_RECORDING, false)
		$PopupMenu.set_item_disabled(MenuItem.OPEN_RECORDING_FOLDER, false)
	if new_state_name == "obs_recording_started":
		$PopupMenu.set_item_text(
			MenuItem.START_STOP_RECORDING,
			"Stop Recording"
		)
	if new_state_name == "obs_recording_stopped":
		$PopupMenu.set_item_text(
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
		$PopupMenu.visible = !$PopupMenu.visible


func _on_popup_menu_id_pressed(id:int):
	match id:
		MenuItem.START_STOP_RECORDING:
			SignalBus.obs_command_requested.emit("ToggleRecord")
		MenuItem.OPEN_RECORDING_FOLDER:
			SignalBus.obs_command_requested.emit("GetProfileParameter", {"parameterCategory": "AdvOut","parameterName": "RecFilePath"})
		MenuItem.CLOSE:
			get_window().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
