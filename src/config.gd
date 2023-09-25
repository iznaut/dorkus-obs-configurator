extends Node


enum SyncEngine {
	NONE,
	UNREAL,
}

const SYNC_NODES = {
	SyncEngine.UNREAL: preload("res://src/game_sync/unreal_engine_sync.tscn")
}

@export_category("Frame.io Integration")
@export var upload_enabled : bool

@export_category("Game Sync")
@export var game_engine : SyncEngine
@export var game_sync_enabled : bool:
	set(new_value):
		_enable_game_sync(new_value)
		game_sync_enabled = new_value
var active_sync_node : GameSync

var start_record_func = func(): OBSHelper.send_command("StartRecord")
var stop_record_func = func(): OBSHelper.send_command("StopRecord")


func _ready():
	OBSHelper.recording_saved.connect(_upload_file_to_frameio)

	# set defaults based on user preferences
	var user_upload_enabled = Utility.get_config_value("Dorkus", "UploadEnabled")
	var user_sync_enabled = Utility.get_config_value("Dorkus", "GameSyncEnabled")
	print(user_sync_enabled)

	if user_upload_enabled != null:
		upload_enabled = user_upload_enabled
	if user_sync_enabled != null:
		game_sync_enabled = user_sync_enabled


func _enable_game_sync(enabled : bool):
	if enabled:
		active_sync_node = SYNC_NODES[game_engine].instantiate()
		add_child(active_sync_node)

		active_sync_node.game_connected.connect(start_record_func)
		active_sync_node.game_disconnected.connect(stop_record_func)

		active_sync_node.request_connection()
	else:
		active_sync_node.game_connected.disconnect(start_record_func)
		active_sync_node.game_disconnected.disconnect(stop_record_func)

		active_sync_node.queue_free()


func _upload_file_to_frameio(filepath):
	var frameio_config = Utility.get_frameio_config()

	if not upload_enabled or not frameio_config is Array:
		return
	
	var output = []
	var params = [
		frameio_config[0],
		frameio_config[1],
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

	# TODO use utility call, is blocking
	OS.execute(upload_script, params, output, true, false)

	var result = JSON.parse_string(output[0])

	print(output)

	StateMachine.state_updated.emit(StateMachine.NOTIFICATION)
	StateMachine.notification_updated.emit("Download success!", StateMachine.DEFAULT_NOTIFICATION_TIME)
	await get_tree().create_timer(1).timeout
