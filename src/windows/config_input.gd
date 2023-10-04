extends LineEdit
class_name ConfigInput


@export var section : String
@export var key : String


func _ready():
	text = Config.get_value(section, key)

	Config.options_saved.connect(_on_options_saved)


func _on_options_saved():
	Config.set_value(
		section,
		key, 
		text
	)
