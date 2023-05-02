extends CanvasLayer

const ObsWebsocket: GDScript = preload("res://addons/obs-websocket-gd/obs_websocket.gd")
#const ObsUi: PackedScene = preload("res://addons/obs_websocket_gd/obs_ui.tscn")

var obs_websocket: Node
var obs_ui: Control

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	obs_websocket = ObsWebsocket.new()
	add_child(obs_websocket)
	
	obs_websocket.connect("data_received", Callable(self,"_on_obs_data_received"))
	obs_websocket.data_received.connect(func(data) -> void:
		print(data.get_as_json())
	)
	
	obs_websocket.establish_connection()
	
	await obs_websocket.connection_authenticated
	
	obs_websocket.send_command("GetVersion")

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################



func _send_command(cmd : String):
	obs_websocket.send_command(cmd)


func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		# _send_command("GetProfileParameter")
		obs_websocket.send_command("GetProfileParameter", {"parameterCategory": "AdvOut","parameterName": "RecFilePath"})
		# obs_websocket.send_command("StartRecord")


func _on_obs_data_received(data):
	print(data)