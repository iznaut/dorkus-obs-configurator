extends Control

@onready var fields = find_children("", "TextEdit", true)


func _submit_to_favro(data):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)

	var body = JSON.stringify(data)
	var error = http_request.request(
		Config.favro_api_url + "/cards",
		[
			"organizationId: " + Config.favro_org_id,
			"Authorization: Basic " + str(Marshalls.utf8_to_base64(str(Utility.get_user_config("Auth", "FavroEmail"), ":", Utility.get_user_config("Auth", "FavroToken")))),
			"Content-Type: application/json"
		],
			HTTPClient.METHOD_POST,
			body
			)
	if error != OK:
		push_error("An error occurred in the HTTP request.")


# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()

	# Will print the user agent string used by the HTTPRequest node (as recognized by httpbin.org).
	print(response_code)



func _on_button_pressed():
	var data = {}

	for field in fields:
		data[field.name] = field.text

	_submit_to_favro(data)


func _on_file_button_pressed():
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	add_child(dialog)
	# dialog.current_dir = config.default_starting_directory
	dialog.title = "Please select a relevant screenshot or video."
	dialog.position = Vector2(800, 800)
	dialog.size = Vector2(800, 800)
	dialog.visible = true

	dialog.file_selected.connect(func(path): print(path))
		
	await dialog.file_selected
