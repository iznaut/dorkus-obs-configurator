extends Control


var obs_path : String = "dorkus-obs/godot.ps1"
var obs_pid : int

@onready var dorkus = $Sprite2D
@onready var anim_player = $Sprite2D/AnimationPlayer
@onready var check_button = $CheckButton


func _ready():
	if OS.has_feature("editor"):
		obs_path = ProjectSettings.globalize_path("res://%s" % obs_path)
	else:
		obs_path = OS.get_executable_path().get_base_dir().path_join(obs_path)


func _on_check_button_toggled(button_pressed : bool):
	if button_pressed:
		check_button.text = "Dorkus is running!"
		anim_player.play("running")
		anim_player.seek(0.375)

		obs_pid = OS.create_process("Start-Process -FilePath obs64.exe -WorkingDirectory './dorkus-obs/bin/64bit/' -PassThru --profile 'NG3 Playtest' --collection 'NG3 Playtest' --startreplaybuffer", [])
	else:
		check_button.text = "Dorkus is sleeping..."
		anim_player.play("RESET")

		print(obs_pid)
		print(OS.kill(obs_pid))