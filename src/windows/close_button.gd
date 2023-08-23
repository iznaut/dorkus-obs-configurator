extends Button


func _on_pressed():
	get_window().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	disabled = true
