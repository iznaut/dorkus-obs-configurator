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

			connection_opened.emit()
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
			has_opened = false

		# wait a bit before trying again
		if not is_closing:
			await get_tree().create_timer(5).timeout

			request_connection()

	last_state = state
