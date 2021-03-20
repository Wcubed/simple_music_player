extends Node

signal playlist_songs_updated()
signal currently_playing_updated(idx, previous_idx)

const FILE_FILTERS := ["*.wav", "*.ogg"]


var Song := preload("song.gd")

var _songs := []

# Indexes into the playlist, only shuffled.
# Once the end is reached, will be re-shuffled.
# This allows forward and backward stepping while shuffling and
# also guarantees all songs are played at least once before looping.
# Get's re-shuffled once new songs are added.
var _shuffled_idxs := []

var _file_checker := File.new()

var _currently_playing := -1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_songs() -> Array:
	return _songs


func get_currently_playing_idx() -> int:
	return _currently_playing


func get_song_by_index(idx: int) -> Object:
	return _songs[idx]


func get_next_song_to_play(shuffle: bool = false) -> Object:
	var previous_playing = _currently_playing
	
	if not shuffle:
		if _currently_playing < 0 or _currently_playing >= _songs.size() -1:
			_currently_playing = 0
		else:
			_currently_playing += 1
	else:
		if _shuffled_idxs.size() == 0:
			_populate_shuffled_indexes_list()
		
		var previous_shuffled_idx = _shuffled_idxs.find(previous_playing)
		var next_shuffled_idx = previous_shuffled_idx + 1
		
		if next_shuffled_idx >= _shuffled_idxs.size():
			# All the songs have played, re-shuffle.
			_populate_shuffled_indexes_list()
			next_shuffled_idx = 0
		
		_currently_playing = _shuffled_idxs[next_shuffled_idx]
	
	if _songs.empty():
		return null
	
	emit_signal("currently_playing_updated", _currently_playing, previous_playing)
	return _songs[_currently_playing]


func _populate_shuffled_indexes_list():
	_shuffled_idxs.clear()
	for i in range(0, _songs.size()):
		_shuffled_idxs.append(i)
	
	_shuffled_idxs.shuffle()


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
	_populate_shuffled_indexes_list()


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
