extends Node


signal options_saved

enum UploadService {
	DISABLED,
	FRAME_IO,
}

enum SyncEngine {
	DISABLED,
	UNREAL,
}

enum ChatApp {
	DISABLED,
	DISCORD,
	SLACK,
	ZOOM,
}

enum InputType {
	DISABLED,
	KEYBOARD_MOUSE,
	GAMEPAD,
}

const SYNC_NODES = {
	SyncEngine.UNREAL: preload("res://src/game_sync/unreal_engine_sync.tscn")
}
const CHAT_APP_SCENES = {
	ChatApp.DISCORD: "Discord",
	ChatApp.SLACK: "Slack",
	ChatApp.ZOOM: "Zoom",
}
const INPUT_OVERLAY_SCENES = {
	InputType.KEYBOARD_MOUSE: "Keyboard/Mouse",
	InputType.GAMEPAD: "Gamepad",
}

@export var use_baked_config : bool = false
@export var allow_user_config : bool = true

var current : ConfigFile
var active_sync_node : GameSync

var start_record_func = func(): OBSHelper.send_command("StartRecord")
var stop_record_func = func(): OBSHelper.send_command("StopRecord")
var setter_funcs = {
	"ReplayBuffer": func(enabled : bool):
		OBSHelper.send_command(
			"%sReplayBuffer" % (
				"Start" if enabled else "Stop"
			)
		),
	"ChatAudio": func(new_value : ChatApp):
		for key in CHAT_APP_SCENES.keys():
			OBSHelper.set_scene_item_enabled(
				"%s Audio" % Config.CHAT_APP_SCENES[key],
				key == new_value
			),
	"InputOverlay": func(new_value : InputType):
		for key in INPUT_OVERLAY_SCENES.keys():
			OBSHelper.set_scene_item_enabled(
				"Input Overlay (%s)" % Config.INPUT_OVERLAY_SCENES[key],
				key == new_value
			),
	"SyncEngine": func(new_value : SyncEngine):
		_toggle_game_sync(new_value != SyncEngine.DISABLED),
}

var baked_config_path = "res://config_baked.ini"
@onready var user_config_path = Utility.globalize_subpath("config.ini")


func _ready():
	# create user config file if missing
	if not FileAccess.file_exists(user_config_path) and allow_user_config:
		var content = FileAccess.get_file_as_string("res://support/config_template.ini")
		var new_file = FileAccess.open(
			user_config_path,
			FileAccess.WRITE
		)
		new_file.store_string(content)
		new_file.close()

	current = ConfigFile.new()
	current.load(
		baked_config_path if use_baked_config else user_config_path
	)

	OBSHelper.recording_saved.connect(_upload_file_to_frameio)

	# run all setters after OBS connects
	OBSHelper.connected.connect(
		func():
			for section in current.get_sections():
				for key in current.get_section_keys(section):
					if key in setter_funcs.keys():
						setter_funcs[key].call(
							get_value(section, key)
						)
	)


func get_value(section : String, key : String) -> Variant:
	return current.get_value(section, key, -1)


func set_value(section : String, key : String, new_value : Variant) -> void:
	current.set_value(section, key, new_value)
	current.save(user_config_path)

	if key in setter_funcs.keys():
		setter_funcs[key].call(new_value)


func _toggle_game_sync(enabled : bool):
	if enabled:
		active_sync_node = SYNC_NODES[
			get_value("Integrations", "SyncEngine")
		].instantiate()

		add_child(active_sync_node)

		active_sync_node.game_connected.connect(start_record_func)
		active_sync_node.game_disconnected.connect(stop_record_func)

		active_sync_node.request_connection()
	else:
		if not active_sync_node:
			return

		active_sync_node.game_connected.disconnect(start_record_func)
		active_sync_node.game_disconnected.disconnect(stop_record_func)

		active_sync_node.queue_free()


func _upload_file_to_frameio(filepath):
	var root_asset_id = get_value("Frameio", "RootAssetID")
	var token = get_value("Frameio", "Token")

	if get_value("Integrations", "UploadService") != UploadService.FRAME_IO:
		return
	
	var params = [
		token,
		root_asset_id,
		filepath,
	]

	# use precompiled script exe if shipping build
	var upload_script = OBSHelper.obs_root.path_join("dist/windows/frameio_upload.exe")

	# if exe doesn't exist assume development and use original script
	if not FileAccess.file_exists(upload_script):
		upload_script = "python"
		params.push_front(
			Utility.globalize_subpath("obs/frameio_upload.py") if OS.has_feature("template") else ProjectSettings.globalize_path("res://support/obs/frameio_upload.py")
		)

	print("running %s" % upload_script)

	StateMachine.state_updated.emit(StateMachine.LOADING)
	await get_tree().create_timer(0.1).timeout

	# TODO not as async as i hoped
	var result = Utility.os_execute_async(upload_script, params)

	StateMachine.state_updated.emit(StateMachine.NOTIFICATION)

	StateMachine.notification_updated.emit(
		"Upload success!" if result else "Upload failed!!!",
		StateMachine.DEFAULT_NOTIFICATION_TIME
	)
