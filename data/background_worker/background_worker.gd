extends Node

# Should be handled "deferred", otherwise the target function isn't called.
signal results_ready()

# type: TASK_SCAN_SONGS - scan a directory for songs, or check if a file is a song.
# task:
#   path: directory or file to scan.
# result:
#   songs: Array of found `Songs`
# type: TASK_LOAD_COVER_IMAGE - load a cover image for a song, if it exists.
# task:
#   path: path to the song to load thee cover image for.
#   song_idx: index of the song in the library, for returning in the result
# result:
#   image: cover image
#   song_idx: index of the song in the library.
# 
enum {TASK_SCAN_SONGS, TASK_LOAD_COVER_IMAGE}

const AUDIO_FILE_FILTERS := ["*.wav", "*.ogg"]
const COVER_ART_FILE_EXTENSIONS := ["jpg", "png"]

var Song := preload("../song.gd")

var _exit_thread := false

# A queue of dictionaries specifying a task.
# See the TASK_* enum for dictionary contents.
var _work_queue := []
# An array of dictionaries of task results.
# See the TASK_* enum for dictionary contents.
var _results := []

var _current_result_data := []

var _file_checker := File.new()

var _thread := Thread.new()
var _mutex := Mutex.new()
var _work_semaphore := Semaphore.new()

# Functions begining with `_thread` should only be called form the worker thread.
# all the other functions should only be called from the main thread.

func _ready():
	_thread.start(self, "_thread_background_worker")


func _exit_tree():
	_mutex.lock()
	_exit_thread = true
	_mutex.unlock()
	
	_work_semaphore.post()
	
	_thread.wait_to_finish()


func add_task(task: Dictionary):
	_mutex.lock()
	_work_queue.append(task)
	_mutex.unlock()
	
	_work_semaphore.post()


func get_results() -> Array:
	_mutex.lock()
	var results := _results
	_results = []
	_mutex.unlock()
	return results


func _thread_background_worker(userdata):
	while true:
		_work_semaphore.wait()
		
		_mutex.lock()
		var exit := _exit_thread
		_mutex.unlock()
		
		if exit:
			break
		elif not _work_queue.empty():
			_thread_do_work()


func _thread_do_work():
	_mutex.lock()
	var task: Dictionary = _work_queue.pop_front()
	_mutex.unlock()
	
	_current_result_data = []
	
	var task_type: int = task["type"]
	
	if task_type == TASK_SCAN_SONGS:
		var path: String = task["path"]
		if _file_checker.file_exists(path):
			if _thread_file_matches_audio_file_filters(path):
				_thread_scan_song(path)
		else:
			_thread_scan_songs_recursive(path)
		
		var result := {
			"type": TASK_SCAN_SONGS,
			"songs": _current_result_data
		}
		_mutex.lock()
		_results.append(result)
		_mutex.unlock()
		
		emit_signal("results_ready")
	elif task_type == TASK_LOAD_COVER_IMAGE:
		var path: String = task["path"]
		var image := _thread_try_load_detached_cover_art(path)
		
		if image != null:
			var result := {
				"type": TASK_LOAD_COVER_IMAGE,
				"image": image,
				"song_idx": task["song_idx"],
			}
			
			_mutex.lock()
			_results.append(result)
			_mutex.unlock()
			
			emit_signal("results_ready")


func _thread_scan_song(path: String):
	path = ProjectSettings.globalize_path(path)
	var song := Song.new(path, path.get_file())
	_current_result_data.append(song)


func _thread_scan_songs_recursive(path: String):
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
			_thread_scan_songs_recursive(full_path)
		elif _thread_file_matches_audio_file_filters(full_path):
			_thread_scan_song(full_path)
	
	dir.list_dir_end()


func _thread_file_matches_audio_file_filters(path: String) -> bool:
	var valid := false
	for filter in AUDIO_FILE_FILTERS:
		if path.matchn(filter):
			valid = true
			break
	return valid


# Tries to load an image file with the same name as, and in the directory of, the song.
# Returns `null` if there is no such image.
func _thread_try_load_detached_cover_art(path: String) -> ImageTexture:
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
