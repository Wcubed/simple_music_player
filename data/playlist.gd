extends Node

signal playlist_songs_updated()
signal currently_playing_updated(idx, previous_idx)

const FILE_FILTERS := ["*.wav", "*.ogg"]


var Song := preload("song.gd")

var _songs := []

# A list of indexes into the playlist mapping to null values (its a hash set).
# Pick a random one from this dictionary when a next song is requested.
# Indexes are removed each time a song is played.
# Guarantees all songs are played at least once before looping.
# New songs are simply added to the dictionary.
var _shuffled_idxs_still_to_play := {}

var _file_checker := File.new()

var _currently_playing := -1

# Called when the node enters the scene tree for the first time.
func _ready():
	# Make sure the shuffle is different each time the program is run.
	randomize()


func get_songs() -> Array:
	return _songs


func get_currently_playing_idx() -> int:
	return _currently_playing


func play_song_by_index(idx: int, remove_from_shuffle: bool = false) -> Object:
	var previous = _currently_playing
	_currently_playing = idx
	
	if remove_from_shuffle:
		_shuffled_idxs_still_to_play.erase(idx)
	
	emit_signal("currently_playing_updated", _currently_playing, previous)
	return _songs[idx]


func play_next_song(shuffle: bool = false) -> Object:
	var previous_playing = _currently_playing
	
	if not shuffle:
		if _currently_playing < 0 or _currently_playing >= _songs.size() -1:
			_currently_playing = 0
		else:
			_currently_playing += 1
	else:
		if _shuffled_idxs_still_to_play.size() == 0:
			_populate_shuffled_indexes_list()
		
		var pick: int = randi() % _shuffled_idxs_still_to_play.size()
		_currently_playing = _shuffled_idxs_still_to_play.keys()[pick]
		_shuffled_idxs_still_to_play.erase(_currently_playing)
	
	if _songs.empty():
		return null
	
	emit_signal("currently_playing_updated", _currently_playing, previous_playing)
	return _songs[_currently_playing]


func _populate_shuffled_indexes_list():
	_shuffled_idxs_still_to_play.clear()
	for i in range(0, _songs.size()):
		_shuffled_idxs_still_to_play[i] = null


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
	_shuffled_idxs_still_to_play[_songs.size()-1] = null

func _load_detached_cover_art(path: String):
	# TODO:
	pass


func add_songs(paths: Array):
	for path in paths:
		add_song(path, false)
	
	emit_signal("playlist_songs_updated")


func add_songs_from_directory(path: String):
	_add_songs_from_directory_recursive(path)
	emit_signal("playlist_songs_updated")

func _add_songs_from_directory_recursive(path: String):
	var dir := Directory.new()
	dir.open(path)
	
	dir.list_dir_begin(true)
	var result := {}
	while true:
		var file: String = dir.get_next()
		var full_path: String = path + "/" + file
		
		if file == "":
			break
		if dir.current_is_dir():
			# Recurse!
			_add_songs_from_directory_recursive(full_path)
		elif _file_matches_filters(full_path):
			add_song(full_path)
	
	dir.list_dir_end()

func _file_matches_filters(path: String) -> bool:
	var valid := false
	for filter in FILE_FILTERS:
		if path.matchn(filter):
			valid = true
			break
	return valid
