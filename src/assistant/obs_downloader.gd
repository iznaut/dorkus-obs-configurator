extends ProgressBar


signal download_complete

@export var obs_download_url : String = "https://github.com/obsproject/obs-studio/releases/download/29.1.3/OBS-Studio-29.1.3.zip"

var http
var download_path : String = Utility.globalize_subpath().path_join("obs.zip")


func _process(_delta):
	if http:
		var bodySize = http.get_body_size()
		var downloadedBytes = http.get_downloaded_bytes()
				
		var percent = int(downloadedBytes*100/bodySize)
		value = percent


func start_download():
	download(obs_download_url, download_path)
	%Assistant.state_updated.emit("obs_downloading")
	get_parent().show()


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

	get_parent().hide()

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
	Utility.create_gdignore(%OBSHelper.obs_root)
	
	download_complete.emit()
	%Assistant.state_updated.emit("obs_downloaded")
