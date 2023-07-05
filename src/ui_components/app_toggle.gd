extends Button


signal app_started
signal app_terminated


@export var app_title : String
@export var target_file : String
@export var auto_start : bool = false

var app_path : String
var app_process_id : int = -1


func _ready():
	if Utility.get_user_config("AppPaths", app_title) == "":
		Utility.set_user_config("AppPaths", app_title, Utility.globalize_path("res://dorkus-obs/bin/64bit/obs64.exe"))

	text = text.replace("[AppName]", app_title)
	app_path = Utility.get_user_config("AppPaths", app_title)


func _process(_delta):
	if auto_start and app_started.get_connections().size() > 0:
		button_pressed = true
		# toggled.emit(true)
		auto_start = false

	if disabled and OS.is_process_running(app_process_id):
		text = "%s is running!" % app_title
		add_theme_color_override("font_color", Color.GREEN)
		disabled = false

	# print(OS.is_process_running(app_process_id))


func _on_toggled(is_newly_pressed : bool):
	if app_path == "":
		var dialog = summon_file_dialog()

		dialog.file_selected.connect(func(path): Utility.set_user_config("AppPaths", app_title, path); app_path = path)
		
		await dialog.file_selected

	# var global_app_path = Utility.globalize_path(app_path)

	if is_newly_pressed:		
		OS.create_process(
			"CMD.exe",
			[
				"/C",
				"%s && cd %s && %s" % [app_path.left(2), app_path.get_base_dir(), app_path.get_file()]
			]
		)

		var output = []

		OS.execute(
			"PowerShell.exe",
			[
				"-Command",
				"(Get-Process %s).Id" % target_file.get_basename()
			],
			output
		)

		app_process_id = output[0].replace("\\r\\n", "") as int

		app_started.emit()
		disabled = true
	else:
		OS.kill(app_process_id)
		app_process_id = -1

		app_terminated.emit()


func summon_file_dialog() -> FileDialog:
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = [target_file]
	add_child(dialog)
	# dialog.current_dir = config.default_starting_directory
	dialog.title = "Please select a valid path to %s" % app_title
	dialog.position = Vector2(800, 800)
	dialog.size = Vector2(800, 800)
	dialog.visible = true

	return dialog


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if button_pressed and app_process_id != -1:
			OS.kill(app_process_id)

		print(app_process_id)
		if app_process_id == -1:
			OS.alert("test")
		
		get_tree().quit() # default behavior
