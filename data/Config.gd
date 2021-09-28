extends Node

const FILE := "user://settings.cfg"

const PATHS_SECTION := "paths"
const SONG_LIBARY_KEY := "song_library"

var _song_library_folder := "" setget set_library_folder, library_folder

func _ready():
	pass # Replace with function body.

func load_from_disk():
	var config = ConfigFile.new()
	var err = config.load(FILE)
	
	print(ProjectSettings.globalize_path(FILE))
	
	if err == OK:
		_song_library_folder = config.get_value(PATHS_SECTION, SONG_LIBARY_KEY, "")


func save_to_disk():
	var config = ConfigFile.new()
	
	config.set_value(PATHS_SECTION, SONG_LIBARY_KEY, _song_library_folder)
	
	config.save(FILE)


func set_library_folder(value: String):
	_song_library_folder = value

func library_folder() -> String:
	return _song_library_folder
