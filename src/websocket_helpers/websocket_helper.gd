extends Node
class_name WebsocketHelper


signal connection_opened
signal connection_closed
signal data_received(data)

enum LogLevel {
	DISABLED,
	STATE_ONLY,
	VERBOSE
}

@export var host : String = "127.0.0.1"
@export var port : int = 445
@export var log_level : LogLevel = LogLevel.DISABLED

var socket
var state : WebSocketPeer.State
var last_state : WebSocketPeer.State
var app_process_id : int = -1


func _ready():
	set_process(false)
	# disable normal quit behavior so we can safely handle app close first
	get_tree().set_auto_accept_quit(false)

	# logging
	if log_level == LogLevel.STATE_ONLY:
		connection_opened.connect(
			func():	
				print("%s Connected Successfully" % name)
		)
		connection_closed.connect(
			func():	
				print("%s Connection Closed" % name)
		)
	if log_level == LogLevel.VERBOSE:
		data_received.connect(
			func(data): 
				print(data)
		)


func request_connection() -> void:
	set_process(true)
	socket = WebSocketPeer.new()
	socket.connect_to_url("ws://%s:%s" % [host, port])


func _on_close_request():
	pass
