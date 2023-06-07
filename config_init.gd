extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	if not FileAccess.file_exists("user://user.cfg"):
		return # Error! We don't have a save to load.
