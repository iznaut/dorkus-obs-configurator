extends TextureRect


var active_state_data : AssistState
var current_frame_index : int
var last_state_name : String

@export var default_idle_frame : Texture2D
@export var default_notification_frame : Texture2D

@onready var anim_timer = $AnimationTimer


func _ready():
	OBSHelper.state_updated.connect(_on_obs_state_updated)


func _on_obs_state_updated(new_state_name : String):
	print("anim state changed: %s " % new_state_name)

	if new_state_name == "idle":
		texture = default_idle_frame
		active_state_data = null
		last_state_name = "idle"
		return

	active_state_data = Utility.get_state_data_from_string(new_state_name)

	if active_state_data == null:
		texture = default_notification_frame
		return

	if active_state_data.has_frames():
		current_frame_index = 0
		texture = active_state_data.frames[current_frame_index]
	else:
		texture = default_notification_frame

	if active_state_data.is_animated():
		anim_timer.wait_time = active_state_data.delay

	if active_state_data.continuous and new_state_name != last_state_name:
		last_state_name = new_state_name

	# wait a bit before clearing notification
	if active_state_data.timeout > 0 and not active_state_data.continuous:
		if last_state_name:
			await get_tree().create_timer(active_state_data.timeout).timeout
			_on_obs_state_updated(last_state_name)
			return
		# if not a repeating animation, return to idle
		# TODO these are non-blocking so there can be conflicts with timers going off
		if active_state_data == null or not active_state_data.is_animated():
			_on_obs_state_updated("idle")


func _on_animation_timer_timeout():
	if active_state_data and active_state_data.is_animated():
		current_frame_index += 1
		if current_frame_index >= active_state_data.frames.size():
			current_frame_index = 0

		texture = active_state_data.frames[current_frame_index]

	anim_timer.start()
