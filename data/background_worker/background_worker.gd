extends Node

# Should be handled "deferred", otherwise the target function isn't called.
signal results_ready()

# TASK_SCAN_SONGS: scan a directory for songs, or check if a file is a song.
# data: the path to the directory or file
# result: a list of songs (if there are any)
enum {TASK_SCAN_SONGS}

const AUDIO_FILE_FILTERS := ["*.wav", "*.ogg"]

var Song := preload("../song.gd")
var Result := preload("worker_result.gd")

var _exit_thread := false

# A queue of `worker_task`.
var _work_queue := []
# An array of `worker_result`
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


func add_task(task: Object):
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
	var task: Object = _work_queue.pop_front()
	_mutex.unlock()
	
	_current_result_data = []
	
	if task.task_type == TASK_SCAN_SONGS:
		var path: String = task.data
		if _file_checker.file_exists(path):
			if _thread_file_matches_audio_file_filters(path):
				_thread_scan_song(path)
		else:
			_thread_scan_songs_recursive(path)
		
		var result := Result.new(TASK_SCAN_SONGS, _current_result_data)
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
