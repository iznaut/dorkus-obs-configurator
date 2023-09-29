extends Control


func _ready():
	get_window().size = size


func _on_options_window_close_requested():
	StateMachine.state_updated.emit(StateMachine.IDLE)
	get_window().queue_free()


func _on_close_button_pressed():
	get_window().queue_free()
	get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _on_save_button_pressed():
	Config.options_saved.emit()
	_on_options_window_close_requested()
