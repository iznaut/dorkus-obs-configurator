extends Control

signal notification_requested(text)

const BUG_REPORT = preload("res://bug_report.tscn")

@onready var window = $Window
@onready var dorkus = $Window/Dorkus
@onready var notif_bubble = $Window/NotificationBubble
@onready var bug_button = $Window/Button


func _ready():
	notification_requested.connect(_on_notification_requested)
	await get_tree().create_timer(3).timeout
	notif_bubble.hide()


func _on_replay_buffer_saved():
	notification_requested.emit("Replay saved!")
	# create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN).tween_property(self, "position", self.position + Vector2i(0,100), 1)


func _on_notification_requested(text : String):
	notif_bubble.show()
	notif_bubble.find_child("Label").text = text
	await get_tree().create_timer(3).timeout
	notif_bubble.hide()


func _on_button_pressed():
	var bug_window = Popup.new()
	bug_window.add_child(BUG_REPORT.instantiate())
	add_child(bug_window)
