extends Control


@onready var window = get_window()
@onready var bubble := $NotificationBubble
@onready var timer := $NotificationBubble/Timer
@onready var label := $NotificationBubble/Label


func _ready():
	StateMachine.notification_updated.connect(_on_notification_updated)


func _on_notification_updated(message : String, duration : float):
	window.visible = true
	label.text = message

	if duration > 0:
		timer.wait_time = duration
		timer.start()


func _on_timer_timeout():
	window.visible = false
	StateMachine.state_updated.emit(StateMachine.IDLE)
