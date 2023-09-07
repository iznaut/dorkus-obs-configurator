extends Control


const BUG_REPORT = preload("res://src/windows/bug_report_window.tscn")

@onready var button_grid = $GridContainer

var assistant : Control
var bug_form : PopupPanel

@export var steam_button : Control


# Called when the node enters the scene tree for the first time.
func _ready():
	# DisplayServer.window_set_title("Dorkus Assistant")
	# size = Vector2i(640,480)
	get_window().transparent_bg = true

	var bug_form = BUG_REPORT.instantiate()
	get_window().add_child.call_deferred(bug_form)
	# bug_form.about_to_popup.connect(assistant._on_bug_report_popup)
	# bug_form.popup_hide.connect(assistant._on_bug_report_hide)
	# bug_form.get_node("Control").user_typed.connect(assistant._on_bug_report_user_typed)
	# bug_form.get_node("Control").user_submitted.connect(_on_bug_report_user_submitted)

	# for menu_button in button_grid.get_children():
	# 	menu_button.button_pressed.connect(_on_menu_button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_app_toggle_app_started():
	pass # Replace with function body.
				

func _on_bug_report_button_pressed():
	var favro_email = Utility.get_user_config("Auth", "FavroEmail")
	var favro_token = Utility.get_user_config("Auth", "FavroToken")
	
	if favro_email == "" or favro_token == "":
		OS.shell_open(Utility.get_user_config_path())
	else:
		bug_form.popup()


func _on_open_favro_button_pressed():
	var favro_org_id = Utility.get_user_config("Auth", "FavroOrgId")
	
	if favro_org_id == "":
		OS.shell_open(Utility.get_user_config_path())
	else:
		OS.shell_open(Config.favro_url + "/" + Utility.get_user_config("Auth", "FavroOrgId"))


func _on_bug_report_user_submitted():
	bug_form.hide()
	assistant.notification_requested.emit(assistant.AnimState.NOTEPAD_BUG)


func _on_steam_run_button_pressed():
	var steam_app_id = Utility.get_user_config("SteamConfig", "AppID")

	if steam_app_id == "":
		OS.shell_open(Utility.get_user_config_path())
	else:
		OS.shell_open("steam://rungameid/" + steam_app_id)
		steam_button.button.disabled = true


# func _on_menu_button_pressed(label : String):
# 	match label:
# 		"Launch Game":
# 			_on_steam_run_button_pressed()
# 		"Show Recordings":
# 			OBSHelper._on_recordings_button_pressed()
# 		"Submit Task":
# 			_on_bug_report_button_pressed()
# 		"Open Favro":
# 			_on_open_favro_button_pressed()
