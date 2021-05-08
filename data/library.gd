extends Node

signal songs_added(ids)
signal songs_removed(ids)
signal cover_image_loaded(song_id, image)

# Song id's (numbers) mapped to Song objects.
var _songs := {}
# Next song id to use.
var _next_song_id := 0

var _file_checker := File.new()

# Handy worker for scanning song directories and loading images in a background
# thread.
onready var _background_worker := $BackgroundWorker


func _ready():
	pass


func get_song_by_id(id: int) -> Object:
	return _songs.get(id, null)


func search_songs_by_title(search_text: String) -> Dictionary:
	var search_text_lowercase := search_text.to_lower()
	var matching_songs := {}
	
	for id in _songs.keys():
		var song: Object = _songs[id]
		if song.title.to_lower().find(search_text_lowercase) != -1:
			matching_songs[id] = song
	
	return matching_songs


func queue_scan_for_songs(path: String):
	var task := {
		"type": _background_worker.TASK_SCAN_SONGS,
		"path": path
		}
	_background_worker.add_task(task)


func queue_scan_for_cover_art(song_path: String, song_id: int):
	var task := {
		"type": _background_worker.TASK_LOAD_COVER_IMAGE,
		"path": song_path,
		"song_id": song_id,
		}
	_background_worker.add_task(task)


func add_songs(songs: Array):
	# TODO: reliably Check for duplicates.
	var new_song_ids := []
	
	for song in songs:
		_songs[_next_song_id] = song
		new_song_ids.append(_next_song_id)
		queue_scan_for_cover_art(song.path, _next_song_id)
		
		_next_song_id += 1
	
	print("%s songs added" % songs.size())
	
	emit_signal("songs_added", new_song_ids)


func _on_BackgroundWorker_results_ready():
	var results: Array = _background_worker.get_results()
	
	for result in results:
		var type: int = result["type"]
		if type == _background_worker.TASK_SCAN_SONGS:
			add_songs(result["songs"])
			
		elif type == _background_worker.TASK_LOAD_COVER_IMAGE:
			var id: int = result["song_id"]
			var image: ImageTexture = result["image"]
			
			_songs[id].image = image
			emit_signal("cover_image_loaded", id, image)
