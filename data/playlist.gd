extends Node

signal playlist_songs_updated()
signal currently_playing_updated(idx, previous_idx)
signal cover_image_loaded(idx, image)

var _songs := []

# A list of indexes into the playlist mapping to null values (its a hash set).
# Pick a random one from this dictionary when a next song is requested.
# Indexes are removed each time a song is played.
# Guarantees all songs are played at least once before looping.
# New songs are simply added to the dictionary.
var _shuffled_idxs_still_to_play := {}

var _file_checker := File.new()

var _currently_playing := -1

onready var _background_worker := $BackgroundWorker

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


func scan_for_songs(path: String):
	var task := {
			"type": _background_worker.TASK_SCAN_SONGS,
			"path": path
		}
	_background_worker.add_task(task)


func scan_for_cover_art(song_path: String, idx: int):
	var task := {
			"type": _background_worker.TASK_LOAD_COVER_IMAGE,
			"path": song_path,
			"song_idx": idx,
		}
	_background_worker.add_task(task)


func add_songs(songs: Array):
	# TODO: reliably Check for duplicates.

	for song in songs:
		print("Adding: '%s'" % song.title)

		_songs.append(song)
		var idx := _songs.size() - 1
		_shuffled_idxs_still_to_play[idx] = null

		scan_for_cover_art(song.path, idx)

	emit_signal("playlist_songs_updated")


func _on_BackgroundWorker_results_ready():
	var results: Array = _background_worker.get_results()

	for result in results:
		var type: int = result["type"]
		if type == _background_worker.TASK_SCAN_SONGS:
			add_songs(result["songs"])
		elif type == _background_worker.TASK_LOAD_COVER_IMAGE:
			var idx: int = result["song_idx"]
			var image: ImageTexture = result["image"]

			_songs[idx].image = image
			emit_signal("cover_image_loaded", idx, image)
