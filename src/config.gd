extends Node


enum SyncEngine {
	NONE,
	UNREAL,
}

const SYNC_NODES = {
	SyncEngine.UNREAL: preload("res://src/game_sync/unreal_engine_sync.tscn")
}

@export_category("Game Sync")
@export var game_engine : SyncEngine
@export var enable_sync_by_default : bool
var active_sync_node : GameSync
var game_sync_enabled : bool:
	set(new_value):
		_enable_game_sync(new_value)
		game_sync_enabled = new_value

@export_category("Frame.io Integration")
@export var enable_upload_by_default : bool
@export var frameio_root_asset_id : String
@export var frameio_token : String
var upload_enabled : bool

var start_record_func = func(): OBSHelper.send_command("StartRecord")
var stop_record_func = func(): OBSHelper.send_command("StopRecord")

func _ready():
	OBSHelper.recording_saved.connect(_upload_file_to_frameio)

	var user_root_asset_id = Utility.get_user_config("Frameio", "RootAssetID")
	var user_token = Utility.get_user_config("Frameio", "Token")

	if user_root_asset_id != "":
		frameio_root_asset_id = user_root_asset_id
	if user_token != "":
		frameio_token = user_token


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
	if not upload_enabled:
		return
	
	var output = []
	var params = [
		frameio_token,
		frameio_root_asset_id,
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

	OBSHelper.state_updated.emit("frameio_upload_%s" % ("succeeded" if result != null else "failed"))
	await get_tree().create_timer(1).timeout
