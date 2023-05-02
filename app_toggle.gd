extends Button

@export var app_title : String
@export_global_file("*.exe") var app_path : String	

var app_process_id : int = -1


func _ready():
	text = text.replace("[AppName]", app_title)


func _on_toggled(button_pressed : bool):
	if button_pressed:
		# OS.execute(app_path, [])
		# print(OS.execute("CMD.exe", ["/C", "cd %TEMP% && dir"]))
		app_process_id = OS.execute(app_path, [])
		print(app_process_id)
	else:
		OS.kill(app_process_id)
		app_process_id = -1
