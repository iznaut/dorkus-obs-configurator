extends VBoxContainer


@export var label : String
@export_global_dir var starting_path : String


func _ready():
	$Label.text = label


func _on_button_pressed():
	get_viewport().set_embedding_subwindows(false)
	var d = FileDialog.new()
	d.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	d.access = FileDialog.ACCESS_FILESYSTEM
	add_child(d)
	d.visible = true
	d.position = Vector2(800, 800)
	d.title = "my title"
	d.size = Vector2(300, 200)
