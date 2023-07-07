extends Control

signal notification_requested(text)

const BUG_REPORT = preload("res://src/windows/bug_report_window.tscn")

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
@export var button_open : String = "Create Favro Task"
@export var button_close : String = "Close Task Window"

@export_category("Assistant Config")
@export var menu_scene : PackedScene
@export var texture_lookup : Array[Texture]

var anim_state : AnimState:
	set(new_state):
		dorkus.texture = texture_lookup[new_state]
		anim_state = new_state

@onready var dorkus = $CharacterGroup/Dorkus
@onready var notif_bubble = $CharacterGroup/SpeechBubble
@onready var bug_button = $Button
@onready var timer = $Timer
@onready var parent_window = get_parent()

var bug_form : PopupPanel
var open_menu : PopupMenu


func _ready():
	notification_requested.connect(_on_notification_requested)
	# await get_tree().create_timer(3).timeout
	# notif_bubble.hide()


func _on_replay_buffer_saved():
	notification_requested.emit(AnimState.SPEAKING, replay_saved_notification)
	# create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN).tween_property(self, "position", self.position + Vector2i(0,100), 1)


func _on_notification_requested(new_anim_state : AnimState, text : String = ""):
	anim_state = new_anim_state

	if text:
		notif_bubble.show()
		notif_bubble.find_child("Label").text = text

	await get_tree().create_timer(3).timeout
	notif_bubble.hide()
	anim_state = AnimState.IDLE


func _on_bug_report_popup():
	# bug_button.text = button_close
	anim_state = AnimState.WRITING_UP

func _on_bug_report_hide():
	timer.stop()
	# bug_button.text = button_open
	anim_state = AnimState.IDLE


func _on_bug_report_user_submitted():
	# bug_form.hide()
	notification_requested.emit(AnimState.NOTEPAD_BUG)


func _on_bug_report_user_typed():
	var writing_toggle = anim_state == AnimState.WRITING_DOWN_1
	anim_state = AnimState.WRITING_DOWN_2 if writing_toggle else AnimState.WRITING_DOWN_1

	timer.start()


func _on_timer_timeout():
	anim_state = AnimState.WRITING_UP
