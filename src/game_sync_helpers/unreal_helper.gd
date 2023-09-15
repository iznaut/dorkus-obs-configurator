extends WebsocketHelper


@export var remote_preset : String = "DorkusAssist"

var has_opened : bool = false


func _process(_delta):
	state = socket.get_ready_state()

	socket.poll()

	if state == WebSocketPeer.STATE_OPEN:
		if last_state == WebSocketPeer.STATE_CONNECTING:
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

			connection_opened.emit()
			# SignalBus.state_update_requested.emit("unreal_connected")
			has_opened = true

		while socket.get_available_packet_count():
			var data = socket.get_packet().get_string_from_utf8()
			data_received.emit(JSON.parse_string(data))
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.

		if has_opened:
			connection_closed.emit()
			# SignalBus.state_update_requested.emit("unreal_disconnected")
			has_opened = false

		# wait a bit before trying again
		if not is_closing:
			await get_tree().create_timer(5).timeout

			request_connection()

	last_state = state


func _update_input_overlay(input_type):
	var is_keyboard = input_type in ["Keyboard", "Mouse"]
	var input_to_enable = "Keyboard/Mouse" if is_keyboard else "Gamepad"
	var input_to_disable = "Keyboard/Mouse" if not is_keyboard else "Gamepad"
	
	_set_input_overlay_visible(input_to_enable, true)
	_set_input_overlay_visible(input_to_disable, false)


func _set_input_overlay_visible(input : String, visible : bool):
	get_parent().obs_command_requested.emit(
		"SetSceneItemEnabled",
		{
			"sceneName": "Playtest",
			"sceneItemId": get_parent().scene_item_list["Input Overlay (%s)" % input],
			"sceneItemEnabled": visible
		}
	)
	

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
