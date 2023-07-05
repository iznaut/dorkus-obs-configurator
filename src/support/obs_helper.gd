extends CanvasLayer


signal replay_buffer_saved

const ObsWebsocket: GDScript = preload("res://addons/obs-websocket-gd/obs_websocket.gd")

@export var app_toggle : Button
@export var recording_list : VBoxContainer
@export var recording_list_item : PackedScene

var obs_websocket : Node
var default_recording_path : String
var user_recording_path : String


func _ready():
	app_toggle.app_started.connect(connect_websocket)

	# user_recording_path = Utility.get_user_config("Cached", "RecFilePath")


func connect_websocket() -> void:
	obs_websocket = ObsWebsocket.new()
	add_child(obs_websocket)

	_on_obs_connecting()

	obs_websocket.connection_closed.connect(_on_obs_disconnected)
	obs_websocket.data_received.connect(_on_obs_data_recieved)
	
	obs_websocket.establish_connection()
	
	await obs_websocket.connection_authenticated

	_on_obs_connected()
	
	# obs_websocket.send_command("GetVersion")
	obs_websocket.send_command("GetProfileParameter", {"parameterCategory": "AdvOut","parameterName": "RecFilePath"})


func _on_obs_data_recieved(data):
	data = JSON.parse_string(data.get_as_json()).d

	print(data)

	if data.has("requestType"):
		print(data.requestType)

		if data.requestType == "GetProfileParameter":
			default_recording_path = data.responseData.defaultParameterValue
			user_recording_path = data.responseData.parameterValue

			# Utility.set_user_config("Cached", "RecFilePath", user_recording_path)
	if data.has("eventType"):
		print(data.eventType)

		if data.eventType == "ReplayBufferSaved":
			replay_buffer_saved.emit()

			var new_list_item = recording_list_item.instantiate()
			var new_filepath = data.eventData.savedReplayPath

			# var dir_access = DirAccess.new()
			var dir = DirAccess.open(user_recording_path)
			var renamed_filepath = new_filepath.replace("Replay", "NG3")
			dir.rename(new_filepath.get_file(), renamed_filepath.get_file())

			new_list_item.get_node("Link").uri = renamed_filepath
			new_list_item.get_node("Link").text = renamed_filepath.get_file()

			recording_list.add_child(new_list_item)


	# assert(false)
	# if data.D.has("requestType"):
	# 	print(data.D.requestType)


func _on_obs_connected():
	app_toggle.text = "%s is connected!" % app_toggle.app_title
	app_toggle.add_theme_color_override("font_color", Color.GREEN)
	app_toggle.disabled = false

	obs_websocket.send_command("StartReplayBuffer")


func _on_obs_connecting():
	app_toggle.text = "%s is starting!" % app_toggle.app_title
	app_toggle.add_theme_color_override("font_color", Color.YELLOW)


func _on_obs_disconnected():
	app_toggle.text = "%s is NOT running" % app_toggle.app_title
	app_toggle.remove_theme_color_override("font_color")
	app_toggle.disabled = false

	obs_websocket.queue_free()


func _on_recordings_button_pressed():
	OS.shell_open(user_recording_path)
