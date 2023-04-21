extends Control


@onready var dorkus = $Sprite2D
@onready var anim_player = $Sprite2D/AnimationPlayer
@onready var check_button = $CheckButton


func _on_check_button_toggled(button_pressed : bool):
	if button_pressed:
		check_button.text = "Dorkus is running!"
		anim_player.play("running")
		anim_player.seek(0.375)
	else:
		check_button.text = "Dorkus is sleeping..."
		anim_player.play("RESET")