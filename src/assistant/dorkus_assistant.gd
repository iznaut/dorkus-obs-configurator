extends Control


func _ready():
	var parent_window = get_window()
	
	@warning_ignore("integer_division")
	parent_window.position = DisplayServer.screen_get_usable_rect().end - parent_window.size
	parent_window.transparent_bg = true

	OBSHelper.state_updated.emit("starting_up")


func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == 2:
		%MenuButton.show_popup()
