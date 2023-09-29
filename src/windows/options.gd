extends Control


func _ready():
	get_window().size = size

	%SelectUploadService.select(%SelectUploadService.get_item_index(Config.upload_service))
	%SelectGameSync.select(%SelectGameSync.get_item_index(Config.sync_engine))


func _on_options_window_close_requested():
	StateMachine.state_updated.emit(StateMachine.IDLE)
	get_window().queue_free()


func _on_close_button_pressed():
	get_window().queue_free()
	get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _on_save_button_pressed():
	Config.upload_service = %SelectUploadService.get_selected_id()
	Config.sync_engine = %SelectGameSync.get_selected_id()
	OBSHelper.set_scene_item_enabled(%OBSSceneToggle.obs_scene_name, %OBSSceneToggle.button_pressed)
	_on_options_window_close_requested()
