extends Control


@onready var anim_sprite := $AnimatedSprite2D
@onready var notif_bubble := $NotificationBubble
@onready var notif_timer := $NotificationBubble/Timer
@onready var notif_label := $NotificationBubble/Label


func _ready():
	StateMachine.state_updated.connect(_on_state_updated)
	StateMachine.notification_updated.connect(_on_notification_updated)


func _on_state_updated(new_state_id : int):
	if new_state_id == StateMachine.IDLE and OBSHelper.is_recording:
		new_state_id = StateMachine.RECORDING
	anim_sprite.animation = StateMachine.STATE_TO_ANIM[new_state_id]


func _on_notification_updated(message : String, duration : float):
	notif_bubble.show()
	notif_label.text = message

	if duration > 0:
		notif_timer.wait_time = duration
		notif_timer.start()


func _on_timer_timeout():
	notif_bubble.hide()
	StateMachine.state_updated.emit(StateMachine.IDLE)
