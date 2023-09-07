extends Control


signal notification_requested(new_state : AssistState)

@export var states : Array[AssistState]

var current_state_config : AssistState
var current_frame_index : int

@onready var dorkus = $CharacterGroup/Dorkus
@onready var notif_bubble = $CharacterGroup/SpeechBubble
@onready var timer = $Timer


func _ready():
	var parent_window = get_window()
	
	@warning_ignore("integer_division")
	parent_window.position = DisplayServer.screen_get_usable_rect().end - parent_window.size
	parent_window.transparent_bg = true
	
	# notification_requested.connect(_on_notification_requested)
	SignalBus.state_update_requested.connect(_update_state)


func _update_state(new_state : AssistState.AppState):
	for state_config in states:
		if state_config.app_state == new_state:
			current_state_config = state_config
			break

	current_frame_index = 0
	dorkus.texture = current_state_config.frames[current_frame_index]

	if current_state_config.message:
		notif_bubble.show()
		notif_bubble.find_child("Label").text = current_state_config.message

	await get_tree().create_timer(3).timeout
	notif_bubble.hide()

	if current_state_config.idle_on_timeout:
		_update_state(AssistState.AppState.IDLE)


func _on_timer_timeout():
	if current_state_config and current_state_config.frames.size() > 1:
		current_frame_index += 1
		if current_frame_index >= current_state_config.frames.size():
			current_frame_index = 0

		dorkus.texture = current_state_config.frames[current_frame_index]

	timer.start()
