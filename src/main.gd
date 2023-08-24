extends Node


func _ready():
	if not Utility.does_config_exist():
		var content = FileAccess.get_file_as_string("res://config_template.ini")
		var new_config = FileAccess.open(Utility.get_config_path(), FileAccess.WRITE)
		new_config.store_string(content)
		new_config.close()

	# TODO python script workaround
	if not FileAccess.file_exists("user://frameio_upload.py"):
		var frameio_python = FileAccess.get_file_as_string("res://support/frameio_upload.py")
		var python_script = FileAccess.open("user://frameio_upload.py", FileAccess.WRITE)
		python_script.store_string(frameio_python)
		python_script.close()


# TODO i just kinda gave up here lmao
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		$OBSHelper.recording_saved.connect(
			func(_filepath):
				OS.kill($OBSHelper.app_process_id)

				get_tree().quit()
		)

		if $OBSHelper.ready_to_close:
			OS.kill($OBSHelper.app_process_id)
			get_tree().quit()
		else:
			$OBSHelper.send_command("StopRecord")


		# var helpers = []

		# Utility.find_by_class(self, "WebsocketHelper", helpers)

		# for helper in helpers:
		# 	helper._on_close_request()
