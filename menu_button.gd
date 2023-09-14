extends MenuButton


var initialized : bool

const POPUP_MENU_SCRIPT = preload("res://src/assistant/menu.gd")


func _on_about_to_popup():
	if not initialized:
		var popup = get_popup()
		popup.set_script(POPUP_MENU_SCRIPT)

		%Assistant.state_updated.connect(popup._on_assistant_state_updated)
		popup.obs_helper = %OBSHelper

		initialized = true
