extends GameSync


@export var remote_preset : String = "DorkusAssist"


func _on_game_connected():
	socket.send_text(
		JSON.stringify(
			{
				"MessageName": "preset.register",
				"Parameters": {
					"PresetName": remote_preset
				}
			}
		)
	)

	$Timer.start()


func _update_input_overlay(input_type):
	var is_keyboard = input_type in ["Keyboard", "Mouse"]
	var input_to_enable = "Keyboard/Mouse" if is_keyboard else "Gamepad"
	var input_to_disable = "Keyboard/Mouse" if not is_keyboard else "Gamepad"
	
	OBSHelper.set_scene_item_enabled("Input Overlay (%s)" % input_to_enable, true)
	OBSHelper.set_scene_item_enabled("Input Overlay (%s)" % input_to_disable, false)


func _on_data_received(data):
	# only looking at responses for now
	if not data.has("ResponseBody"):
		return

	var unreal_data = data.ResponseBody
	var property_display_name = unreal_data.ExposedPropertyDescription.DisplayName
	var property_value = unreal_data.PropertyValues[0].PropertyValue

	if property_display_name == "currentInputType":
		_update_input_overlay(property_value)


func _on_timer_timeout():
	socket.send_text(
		JSON.stringify(
			{
				"MessageName": "http",
				"Parameters": {
					"Url": "/remote/preset/%s/property/currentInputType" % remote_preset,
					"Verb": "GET"
				}
			}
		)
	)
