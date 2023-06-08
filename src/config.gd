extends Node

@export_group("OBS Paths")
@export_file("*.exe") var path_to_obs_exe : String
@export_file("*.ini") var path_to_obs_profile : String
@export_file("*.json") var path_to_obs_scene : String

@export_group("Favro")
@export var favro_api_url : String
@export var favro_org_id : String

var source_remaps = {
		"image_source": {
			"file": "dorkus-white.png"
		},
		"input-overlay": {
			"io.overlay_image": "game-pad.png",
			"io.layout_file": "game-pad.json",
		},
	}
