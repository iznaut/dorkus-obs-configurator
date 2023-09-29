@tool
extends Marker2D


@onready var window = get_child(0)
@onready var screen_space_position = (DisplayServer.screen_get_usable_rect().end - get_window().size) + (self.position as Vector2i)


func _ready():
	if Engine.is_editor_hint():
		set_notify_transform(true)
	else:
		window.position = screen_space_position
		window.hide()


func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		window.position = self.position
