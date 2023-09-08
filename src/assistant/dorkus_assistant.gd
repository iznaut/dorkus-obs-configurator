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

	SignalBus.obs_state_reported.connect(_update_menu_recording_status)
	SignalBus.state_update_requested.connect(_update_state)
	SignalBus.state_update_requested.emit("starting_up")


func _update_state(new_state_name : String):
	if new_state_name == "idle":
		dorkus.texture = default_idle_frame
		current_state_data = null
		return
	if new_state_name == "obs_connected":
		$PopupMenu.set_item_disabled(MenuItem.START_STOP_RECORDING, false)

	current_state_data = load(STATE_DIR.path_join("%s.tres" % new_state_name))

	if not current_state_data:
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

	# wait a bit before clearing notification
	await get_tree().create_timer(current_state_data.timeout).timeout
	notif_bubble.hide()

	# if not a repeating animation, return to idle
	if current_state_data.is_animated():
		timer.wait_time = current_state_data.delay
	else:
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
			record_state_change_requested = true
			SignalBus.obs_state_requested.emit()
		MenuItem.CLOSE:
			get_window().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _update_menu_recording_status(is_recording : bool):
	var status_str = "Stop" if is_recording else "Start"

	if record_state_change_requested:
		status_str = "Start" if not is_recording else "Stop"
		SignalBus.obs_command_requested.emit("%sRecord" % status_str)
		record_state_change_requested = false

	$PopupMenu.set_item_text(
		MenuItem.START_STOP_RECORDING,
		"%s Recording" % status_str
	)
