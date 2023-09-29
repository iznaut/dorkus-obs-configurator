extends Node


@onready var menu_enabled : bool:
	get:
		return menu_enabled and Config.get_value("Assistant", "MenuAccess")


func _ready():
	var parent_window = get_window()
	
	@warning_ignore("integer_division")
	parent_window.position = DisplayServer.screen_get_usable_rect().end - parent_window.size
	parent_window.transparent_bg = true

	StateMachine.state_updated.connect(
		func(new_state_id):
			menu_enabled = new_state_id in [StateMachine.IDLE, StateMachine.RECORDING]
	)

	StateMachine.state_updated.emit(StateMachine.LOADING)
	StateMachine.notification_updated.emit("Setting up, please wait...", 0)

	$Assistant.show()


func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == 2 and menu_enabled:
		%PopupMenu.popup()
