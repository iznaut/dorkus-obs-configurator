extends Control


signal notification_requested(anim, msg)

enum AnimState {
	IDLE,
	SPEAKING,
	NOTEPAD_BLANK,
	NOTEPAD_BUG,
	WRITING_UP,
	WRITING_DOWN_1,
	WRITING_DOWN_2,
}

@export_category("Strings")
@export var replay_saved_notification : String = "Clip saved!"

@export_category("Assistant Config")
@export var texture_lookup : Array[Texture]

var anim_state : AnimState:
	set(new_state):
		dorkus.texture = texture_lookup[new_state]
		anim_state = new_state

@onready var dorkus = $CharacterGroup/Dorkus
@onready var notif_bubble = $CharacterGroup/SpeechBubble
@onready var timer = $Timer
@onready var parent_window = get_parent()


func _ready():
	notification_requested.connect(_on_notification_requested)

	# TODO - find less bad way of aligning to taskbar/screen edge
	var res := DisplayServer.screen_get_size()
	@warning_ignore("integer_division")
	parent_window.position = res - parent_window.size + Vector2i(0, res.y / 2 + 5)

	# override a bunch of options for assistant window
	parent_window.unfocusable = true
	parent_window.always_on_top = true
	parent_window.transparent = true
	parent_window.transparent_bg = true
	parent_window.borderless = true
	parent_window.exclusive = true
	parent_window.popup_window = true
	parent_window.show()

	# connect signals
	# OBSHelper.recording_saved.connect(_on_replay_buffer_saved)


func _on_replay_buffer_saved():
	notification_requested.emit(AnimState.SPEAKING, replay_saved_notification)
	# create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN).tween_property(self, "position", self.position + Vector2i(0,100), 1)


func _on_notification_requested(new_anim_state : AnimState, msg : String = ""):
	anim_state = new_anim_state

	if msg:
		notif_bubble.show()
		notif_bubble.find_child("Label").text = msg

	await get_tree().create_timer(3).timeout
	notif_bubble.hide()
	anim_state = AnimState.IDLE


func _on_bug_report_popup():
	anim_state = AnimState.WRITING_UP


func _on_bug_report_hide():
	timer.stop()
	anim_state = AnimState.IDLE


func _on_bug_report_user_submitted():
	notification_requested.emit(AnimState.NOTEPAD_BUG)


func _on_bug_report_user_typed():
	var writing_toggle = anim_state == AnimState.WRITING_DOWN_1
	anim_state = AnimState.WRITING_DOWN_2 if writing_toggle else AnimState.WRITING_DOWN_1

	timer.start()


func _on_timer_timeout():
	anim_state = AnimState.WRITING_UP
