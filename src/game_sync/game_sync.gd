extends Node
class_name GameSync


signal game_connected
signal game_disconnected
signal data_received(data)

enum ConnectionType {
	WEBSOCKET,
}

@export var connection_type : ConnectionType
@export var host : String = "127.0.0.1"
@export var port : int = 445
@export var logging : bool

var socket
var state : WebSocketPeer.State
var last_state : WebSocketPeer.State
var app_process_id : int = -1


func _ready():
	set_process(false)

	game_connected.connect(_on_game_connected)

	if logging:
		game_connected.connect(
			func():	
				print("%s Connected Successfully" % name)
		)
		game_disconnected.connect(
			func():	
				print("%s Connection Closed" % name)
		)
		data_received.connect(
			func(data): 
				print(data)
		)


func _process(_delta):
	if connection_type == ConnectionType.WEBSOCKET:
		state = socket.get_ready_state()
		socket.poll()

		if state == WebSocketPeer.STATE_OPEN:
			if last_state == WebSocketPeer.STATE_CONNECTING:
				game_connected.emit()

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

			if last_state in [WebSocketPeer.STATE_OPEN, WebSocketPeer.STATE_CLOSING]:
				game_disconnected.emit()

			# wait a bit before trying again
			await get_tree().create_timer(5).timeout
			_request_websocket_connection()

		last_state = state


func request_connection():
	if connection_type == ConnectionType.WEBSOCKET:
		_request_websocket_connection()


func _request_websocket_connection() -> void:
	set_process(true)
	socket = WebSocketPeer.new()
	socket.connect_to_url("ws://%s:%s" % [host, port])


func _on_game_connected():
	pass


# func _notification(what):
# 	if what == NOTIFICATION_WM_CLOSE_REQUEST:
# 		print("websocket close requested")
# 		is_closing = true
# 		state = WebSocketPeer.STATE_CLOSED