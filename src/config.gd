extends Node


var obs_root : String :
	get:
		var target = "dorkus-obs/"

		# use /build if running in editor
		if OS.has_feature("editor"):
			return Utility.get_working_dir() + "build/" + target

		return Utility.globalize_path("res://" + target)
var obs_exe : String :
	get:
		return obs_root + "bin/64bit/obs64.exe"
var obs_profile : String :
	get:
		return obs_root + "config/obs-studio/basic/profiles/NG3_Playtest/basic.ini"
var obs_scene : String :
	get:
		return obs_root + "config/obs-studio/basic/scenes/NG3_Playtest.json"

var unreal_ws_port : int = 38273
var unreal_preset : String = "DorkusAssist"

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
