extends Button
class_name ConfigButton


@export var section : String
@export var key : String

@onready var is_option_button = is_class("OptionButton")

func _ready():
	var initial_value = Config.get_value(section, key)

	if is_option_button:
		set("selected", initial_value)
	else:
		button_pressed = initial_value as int

	Config.options_saved.connect(_on_options_saved)


func _on_options_saved():
	Config.set_value(
		section,
		key, 
		call("get_selected_id") if is_class("OptionButton") else button_pressed as int
	)
