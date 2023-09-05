extends Node


func _ready():
	if not Utility.does_config_exist():
		var content = FileAccess.get_file_as_string("res://config_template.ini")
		var new_config = FileAccess.open(Utility.get_config_path(), FileAccess.WRITE)
		new_config.store_string(content)
		new_config.close()

	# TODO python script workaround
	if not FileAccess.file_exists("user://frameio_upload.exe"):
		var dir = DirAccess.open("user://")
		dir.copy("res://support/frameio_upload.exe", "user://frameio_upload.exe")

	# disable normal quit behavior so we can safely handle app close first
	get_tree().set_auto_accept_quit(false)
