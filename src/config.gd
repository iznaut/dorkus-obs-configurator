extends Node


@export_group("OBS Paths")
@export_file("*.exe") var path_to_obs_exe : String
@export_file("*.ini") var path_to_obs_profile : String
@export_file("*.json") var path_to_obs_scene : String

var favro_url = "https://favro.com/organization"
var favro_api_url = "https://favro.com/api/v1"
var source_remaps = {
		"image_source": {
			"file": "dorkus-white.png"
		},
		"input-overlay": {
			"io.overlay_image": "game-pad.png",
			"io.layout_file": "game-pad.json",
		},
	}
