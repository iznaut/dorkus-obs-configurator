extends Node


enum UploadService {
	DISABLED,
	FRAME_IO,
}

enum SyncEngine {
	DISABLED,
	UNREAL,
}

const SYNC_NODES = {
	SyncEngine.UNREAL: preload("res://src/game_sync/unreal_engine_sync.tscn")
}

@export_category("Config Defaults")
@export var upload_service : UploadService
@export var sync_engine : SyncEngine:
	set(new_value):
		sync_engine = new_value
		_toggle_game_sync(sync_engine != SyncEngine.DISABLED)

var active_sync_node : GameSync

var start_record_func = func(): OBSHelper.send_command("StartRecord")
var stop_record_func = func(): OBSHelper.send_command("StopRecord")


func _ready():
	OBSHelper.recording_saved.connect(_upload_file_to_frameio)

	# set defaults based on user preferences
	var user_upload_service = Utility.get_config_value("Dorkus", "UploadService")
	var user_sync_engine = Utility.get_config_value("Dorkus", "SyncEngine")

	if user_upload_service != -1:
		upload_service = user_upload_service
	if user_sync_engine != -1:
		sync_engine = user_sync_engine


func _toggle_game_sync(enabled : bool):
	if enabled:
		if not OBSHelper.is_connected:
			await OBSHelper.connected

		active_sync_node = SYNC_NODES[sync_engine].instantiate()
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

	if upload_service != UploadService.FRAME_IO or not frameio_config is Array:
		return
	
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

	StateMachine.state_updated.emit(StateMachine.LOADING)
	await get_tree().create_timer(0.1).timeout

	# TODO not as async as i hoped
	var result = Utility.os_execute_async(upload_script, params)

	StateMachine.state_updated.emit(StateMachine.NOTIFICATION)

	StateMachine.notification_updated.emit(
		"Upload success!" if result else "Upload failed!!!",
		StateMachine.DEFAULT_NOTIFICATION_TIME
	)
