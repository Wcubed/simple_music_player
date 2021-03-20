extends Node

signal playlist_songs_updated()
signal currently_playing_updated(idx, previous_idx)

const FILE_FILTERS := ["*.wav", "*.ogg"]


var Song := preload("song.gd")
var _songs := []

var _file_checker := File.new()

var _currently_playing := -1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_songs() -> Array:
	return _songs


func get_currently_playing_idx() -> int:
	return _currently_playing


func get_next_song_to_play() -> Object:
	var previous_playing = _currently_playing
	
	if _currently_playing < 0 or _currently_playing >= _songs.size() -1:
		_currently_playing = 0
	else:
		_currently_playing += 1
	
	if _songs.empty():
		return null
	
	emit_signal("currently_playing_updated", _currently_playing, previous_playing)
	return _songs[_currently_playing]


func add_song(path: String, emit_signal: bool = true):
	if not _file_matches_filters(path):
		print("File does not have a recognized extension, skipping: '%s'" % path)
		return
	if not _file_checker.file_exists(path):
		print("File does not exist, skipping: '%s'" % path)
		return
	
	path = ProjectSettings.globalize_path(path)
	
	# Check for duplicates
	# TODO: can we do a quicker check, with a dictionary or something?
	for song in _songs:
		if song.path == path:
			return
	
	print("Adding: '%s'" % path)
	var song := Song.new(path, path.get_file())
	_songs.append(song)


func add_songs(paths: Array):
	for path in paths:
		add_song(path, false)
	
	emit_signal("playlist_songs_updated")


func add_songs_from_directory(path: String):
	var dir := Directory.new()
	dir.open(path)
	
	dir.list_dir_begin(true)
	var result := {}
	while true:
		var file: String = dir.get_next()
		if file == "":
			break
		if _file_matches_filters(file):
			add_song(path + "/" + file)
	
	dir.list_dir_end()
	emit_signal("playlist_songs_updated")


func _file_matches_filters(path: String) -> bool:
	var valid := false
	for filter in FILE_FILTERS:
		if path.matchn(filter):
			valid = true
			break
	return valid
