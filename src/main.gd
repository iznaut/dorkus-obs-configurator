extends Node


signal close_requested

const ASSISTANT_SCENE := preload("res://src/assistant/dorkus_assistant.tscn")


func _ready():
	if not Utility.does_config_exist():
		var content = FileAccess.get_file_as_string("res://config_template.ini")
		var new_config = FileAccess.open(Utility.get_config_path(), FileAccess.WRITE)
		new_config.store_string(content)
		new_config.close()

	ASSISTANT_SCENE.instantiate()


# TODO i just kinda gave up here lmao
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		$OBSHelper.recording_saved.connect(
			func(_filepath):
				OS.kill($OBSHelper.app_process_id)

				get_tree().quit()
		)

		$OBSHelper.send_command("StopRecord")

		# var helpers = []

		# Utility.find_by_class(self, "WebsocketHelper", helpers)

		# for helper in helpers:
		# 	helper._on_close_request()
