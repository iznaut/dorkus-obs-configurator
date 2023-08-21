extends Node


signal connection_opened
signal connection_closed
signal message_received(data)

var socket = WebSocketPeer.new()
var ready_to_connect : bool = false
var connection_initialized : bool = false


func request_connection():
	socket.connect_to_url("ws://127.0.0.1:%s" % [Config.unreal_ws_port])
	ready_to_connect = true


func _process(_delta):
	if ready_to_connect:
		socket.poll()
		var state = socket.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			if not connection_initialized:
				connection_opened.emit()

				socket.send_text(
					JSON.stringify(
						{
							"MessageName": "preset.register",
							"Parameters": {
								"PresetName": Config.unreal_preset
							}
						}
					)
				)

				connection_initialized = true

			while socket.get_available_packet_count():
				var data = socket.get_packet().get_string_from_utf8()
				message_received.emit(JSON.parse_string(data))
		elif state == WebSocketPeer.STATE_CLOSING:
			# Keep polling to achieve proper close.
			pass
		elif state == WebSocketPeer.STATE_CLOSED:
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			set_process(false) # Stop processing.

			if code == -1 and connection_initialized:
				connection_closed.emit()
				socket = WebSocketPeer.new()
				set_process(true)
				request_connection()

			connection_initialized = false


func _on_message_received(data : Variant):
	print(data)
