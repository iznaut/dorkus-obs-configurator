extends Button


func _on_pressed():
	print("close attempted")
	get_window().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	# disabled = true