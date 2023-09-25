extends MenuButton


const POPUP_MENU_SCRIPT = preload("res://src/assistant/menu.gd")


func _ready():
	var popup = get_popup()
	popup.set_script(POPUP_MENU_SCRIPT)

	popup.config = get_parent()

	popup.hide_on_checkable_item_selection = false
