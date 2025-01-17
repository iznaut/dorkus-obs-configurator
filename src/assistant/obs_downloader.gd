extends VBoxContainer


signal download_complete

@export var obs_download_url : String = "https://github.com/obsproject/obs-studio/releases/download/29.1.3/OBS-Studio-29.1.3.zip"

var http
var download_path : String = Utility.globalize_subpath().path_join("obs.zip")

@onready var progress_bar := $ProgressBar


func _process(_delta):
	if http:
		var bodySize = http.get_body_size()
		var downloadedBytes = http.get_downloaded_bytes()
				
		var percent = int(downloadedBytes*100/bodySize)
		progress_bar.value = percent


func start_download():
	download(obs_download_url, download_path)
	StateMachine.state_updated.emit(StateMachine.LOADING)


func download(link, path):
	http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_http_request_completed)

	http.set_download_file(path)
	var request = http.request(link)
	if request != OK:
		push_error("Http request error")


func _http_request_completed(result, _response_code, _headers, _body):
	if result != OK:
		push_error("Download Failed")
		return
	remove_child(http)

	var output = []

	OS.execute(
		"PowerShell.exe",
		[
			"Set-Location -Path \'%s\';" % Utility.globalize_subpath(),
			"Expand-Archive -Path \'%s\'" % download_path,
		],
		output,
		true, true
	)

	print(output)

	# delete zip
	DirAccess.remove_absolute(download_path)

	# tell godot to ignore this folder to reduce version control mess
	Utility.create_gdignore(OBSHelper.obs_root)
	
	StateMachine.state_updated.emit(StateMachine.NOTIFICATION)
	download_complete.emit()
	queue_free()
