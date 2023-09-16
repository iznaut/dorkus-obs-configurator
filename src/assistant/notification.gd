extends TextureRect


@onready var label = $Label


func _ready():
	OBSHelper.state_updated.connect(_on_obs_state_updated)


func _on_obs_state_updated(new_state_name : String):
	var state_data = Utility.get_state_data_from_string(new_state_name)

	if state_data.message:
		label.text = state_data.message
		show()
		
	if state_data.timeout > 0:
		await get_tree().create_timer(state_data.timeout).timeout
		hide()
