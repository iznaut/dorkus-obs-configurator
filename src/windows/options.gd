extends Control


func _ready():
	# get_window().reset_size()
	_toggle_frameio_config_fields(%SelectUploadService.selected == Config.UploadService.FRAME_IO)


func _on_options_window_close_requested():
	StateMachine.state_updated.emit(StateMachine.IDLE)
	get_window().queue_free()


func _on_close_button_pressed():
	get_window().queue_free()
	get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _on_save_button_pressed():
	Config.options_saved.emit()
	_on_options_window_close_requested()


func _on_tab_bar_tab_changed(tab : int):
	var children = %OptionPanels.get_children()

	for index in children.size():
		var child = children[index]

		child.visible = tab == index


func _on_select_upload_service_item_selected(index : int):
	_toggle_frameio_config_fields(index == Config.UploadService.FRAME_IO)


func _toggle_frameio_config_fields(new_visible : bool):
	%FrameioConfig.visible = new_visible