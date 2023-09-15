extends MenuButton


var initialized : bool

const POPUP_MENU_SCRIPT = preload("res://src/assistant/menu.gd")


func _ready():
	if not initialized:
		var popup = get_popup()
		popup.set_script(POPUP_MENU_SCRIPT)

		popup.assistant = %Assistant
		popup.obs_helper = %OBSHelper

		popup.hide_on_checkable_item_selection = false

		initialized = true


func _on_menu_initialized():
	%Assistant.state_updated.connect(get_popup()._on_assistant_state_updated)