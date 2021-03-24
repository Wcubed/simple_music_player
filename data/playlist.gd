extends Node

signal playlist_songs_updated()
signal currently_playing_updated(idx, previous_idx)

const AUDIO_FILE_FILTERS := ["*.wav", "*.ogg"]
const COVER_ART_FILE_EXTENSIONS := ["jpg", "png"]


var WorkerTask := preload("background_worker/worker_task.gd")

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
	var task := WorkerTask.new(_background_worker.TASK_SCAN_SONGS, path)
	_background_worker.add_task(task)


func add_songs(songs: Array):
	# TODO: reliably Check for duplicates
	
	for song in songs:
		print("Adding: '%s'" % song.title)
		
		_songs.append(song)
		_shuffled_idxs_still_to_play[_songs.size()-1] = null
	
	emit_signal("playlist_songs_updated")


# Tries to load an image file with the same name as, and in the directory of, the song.
# Returns `null` if there is no such image.
func _try_load_detached_cover_art(path: String) -> ImageTexture:
	# TODO: Return cover art and apply to song.
	var base_path := path.get_basename()
	for extension in COVER_ART_FILE_EXTENSIONS:
		var potential_cover_art: String = base_path + "." + extension
		if not _file_checker.file_exists(potential_cover_art):
			continue
		
		var cover_art := Image.new()
		cover_art.load(potential_cover_art)
		var texture := ImageTexture.new()
		texture.create_from_image(cover_art)
		return texture
		
	return null


func _file_matches_audio_file_filters(path: String) -> bool:
	var valid := false
	for filter in AUDIO_FILE_FILTERS:
		if path.matchn(filter):
			valid = true
			break
	return valid


func _on_BackgroundWorker_results_ready():
	var results: Array = _background_worker.get_results()
	
	for result in results:
		if result.task_type == _background_worker.TASK_SCAN_SONGS:
			add_songs(result.data)
