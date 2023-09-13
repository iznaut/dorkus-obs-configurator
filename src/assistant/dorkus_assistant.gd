extends Control


signal state_updated(new_state_name)


func _ready():
	var parent_window = get_window()
	
	@warning_ignore("integer_division")
	parent_window.position = DisplayServer.screen_get_usable_rect().end - parent_window.size
	parent_window.transparent_bg = true

	state_updated.emit("starting_up")


func _on_gui_input(event:InputEvent):
	if event is InputEventMouseButton and event.button_index == 2 and event.pressed:
		%PopupMenu.popup()


func _on_obs_helper_state_update_requested(new_state_name : String):
	state_updated.emit(new_state_name)
