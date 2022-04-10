extends PanelContainer

const MAX_VOLUME_DB := 0.0
const MIN_VOLUME_DB := -60.0

var _stream_total_length: float = 0
var _playback_time: float = 0

var _large_ui_window_size := Vector2(0, 0)
var _large_ui_window_position := Vector2(0, 0)
var _overlay_ui_position = null

var _current_song: Object = null

var _no_padding_panel := preload("resources/no_padding_panel.stylebox")

onready var _config := $Config
onready var _library := $Library
onready var _playlist := $Playlist
onready var _audio_importer := $AudioImporter

onready var _stream_player := $AudioStreamPlayer
onready var _update_timer := $UpdateTimer

onready var _playlist_ui := $VBoxContainer/PlaylistUi
onready var _playback_controls := $VBoxContainer/PlaybackControls
onready var _overlay_controls := $VBoxContainer/OverlayControls

onready var _library_folder_select_dialog := $LibraryFolderSelectDialog


# Called when the node enters the scene tree for the first time.
func _ready():
	_config.load_from_disk()
	
	_library_folder_select_dialog.filters = _library._background_worker.AUDIO_FILE_FILTERS
	_playlist_ui.set_library(_library)
	_playlist.set_infinite(_playback_controls.is_infinite_playlist_enabled())
	_update_song_count()
	
	_set_volume(0.8)
	
	var library_folder: String = _config.library_folder()
	_switch_to_new_library_folder(library_folder)
	
	# Prevent sizing the window so small that the UI doesn't fit anymore.
	OS.min_window_size = get_combined_minimum_size()


func _show_library_dialog_popup():
	_library_folder_select_dialog.popup_centered(Vector2(700, 400))


func _update_song_count():
	_playlist_ui.set_library_song_count(_library.get_song_count())


func _play_next_song():
	var song: Object = _library.get_song_by_id(_playlist.select_next_song())
	_play_song(song)


func _play_previous_song():
	var song: Object = _library.get_song_by_id(_playlist.select_previous_song())
	_play_song(song)


func _play_song_by_idx(idx: int):
	var song: Object = _library.get_song_by_id(_playlist.select_song_by_index(idx))
	
	# When this call is made, it is either because the user clicked a song,
	# or because the currently playing song got moved around the playlist
	# because of songs added or removed before it.
	# In both cases, starting back at the beginning in the same song, isn't
	# what we want.
	if _current_song != song:
		_play_song(song)


func _play_song(song: Object):
	if song == null:
		return

	var audio_stream: AudioStream = _audio_importer.loadfile(song.path)
	_stream_player.stream = audio_stream
	_stream_total_length = audio_stream.get_length()
	_playback_time = 0

	_playback_controls.update_song_title(song.title)
	_overlay_controls.update_song_title(song.title)
	
	_playback_controls.update_cover_image(song.image)
	_overlay_controls.update_cover_image(song.image)
	
	_playback_controls.update_total_time(_stream_total_length)
	_playback_controls.update_time_playing(_playback_time)
	
	_current_song = song
	_play_audio()


func _play_audio():
	if _stream_player.stream == null:
		call_deferred("_play_next_song")
		return

	_update_timer.start()
	_stream_player.play(_playback_time)
	_stream_player.stream_paused = false

	_playback_controls.update_paused(false)
	_overlay_controls.update_paused(false)


func _pause_audio():
	if _stream_player.stream == null:
		return

	_update_timer.stop()
	_stream_player.stream_paused = true

	_playback_controls.update_paused(true)
	_overlay_controls.update_paused(true)


func _audio_finished():
	_play_next_song()


func _seek_timecode(seconds: float):
	if _stream_player.stream == null:
		return
	_playback_time = seconds

	_stream_player.seek(_playback_time)

	_playback_controls.update_time_playing(_playback_time)


# Volume is between 0 and 1.0.
func _set_volume(volume: float):
	_playback_controls.update_volume(volume)
	_stream_player.volume_db = lerp(MIN_VOLUME_DB, MAX_VOLUME_DB, volume)


func _on_UpdateTimer_timeout():
	_playback_time = _stream_player.get_playback_position()
	_playback_controls.update_time_playing(_playback_time)


func _switch_to_overlay_ui():
	_large_ui_window_size = OS.window_size
	_large_ui_window_position = OS.window_position
	
	_playlist_ui.hide()
	_playback_controls.hide()
	_overlay_controls.show()
	
	set("custom_styles/panel", _no_padding_panel)
	
	var min_size := get_combined_minimum_size()
	OS.min_window_size = min_size
	OS.window_size = min_size
	
	OS.set_window_always_on_top(true)
	OS.window_borderless = true
	
	if _overlay_ui_position != null:
		OS.window_position = _overlay_ui_position


func _switch_to_large_ui():
	_overlay_ui_position = OS.window_position
	
	OS.window_position = _large_ui_window_position
	OS.set_window_always_on_top(false)
	OS.window_borderless = false
	OS.max_window_size = Vector2(0, 0)
	OS.window_size = _large_ui_window_size
	
	_overlay_controls.hide()
	set("custom_styles/panel", null)
	
	_playlist_ui.show()
	_playback_controls.show()
	
	var min_size := get_combined_minimum_size()
	OS.min_window_size = min_size


func _switch_to_new_library_folder(folder: String):
	var dir := Directory.new()
	
	if folder != "" && dir.dir_exists(folder):
		_library.clear_songs()
		_library.queue_scan_for_songs(folder)
		
		_config.set_library_folder(folder)
		_config.save_to_disk()


func _unhandled_key_input(event):
	if event.is_action_pressed("ui_right"):
		_seek_timecode(_stream_player.get_playback_position() + 10)
		get_tree().set_input_as_handled()

	elif event.is_action_pressed("ui_left"):
		_seek_timecode(_stream_player.get_playback_position() - 10)
		get_tree().set_input_as_handled()

	elif event.is_action_pressed("music_next"):
		_play_next_song()
		get_tree().set_input_as_handled()

	elif event.is_action_pressed("music_play_pause"):
		if _stream_player.stream_paused:
			_play_audio()
		else:
			_pause_audio()


func _on_PlaybackControls_pause_requested():
	_pause_audio()


func _on_PlaybackControls_play_requested():
	_play_audio()


func _on_PlaybackControls_seek_requested(seconds: float):
	_seek_timecode(seconds)


func _on_AudioStreamPlayer_finished():
	_audio_finished()


func _on_LibaryFolderSelectDialog_dir_selected(dir: String):
	_switch_to_new_library_folder(dir)


func _on_PlaybackControls_next_song_requested():
	_play_next_song()


func _on_PlaybackControls_volume_change_requested(new_volume: float):
	_set_volume(new_volume)


func _on_PlaybackControls_previous_song_requested():
	_play_previous_song()


func _on_Library_cover_image_loaded(song_id: int, image: ImageTexture):
	if song_id == _playlist.get_current_song_id():
		_playback_controls.update_cover_image(image)
		_overlay_controls.update_cover_image(image)


func _on_PlaylistUi_play_song_by_index_requested(idx: int):
	_play_song_by_idx(idx)


func _on_PlaybackControls_infinite_playlist_button_toggled(new_state: bool):
	_playlist.set_infinite(new_state)


func _on_PlaylistUi_remove_song_by_index_requested(idx: int):
	_playlist.remove_song_at_index(idx)
	
	if _playlist.get_current_song_idx() == idx:
		# If the currently playing song was deleted, 
		_play_song_by_idx(idx)


func _on_PlaylistUi_add_song_to_playlist_requested(id: int):
	_playlist.add_song_after_current_song(id)


func _on_Library_songs_added(_ids):
	_update_song_count()


func _on_Library_songs_removed(_ids):
	_update_song_count()


func _on_PlaybackControls_overlay_ui_requested():
	_switch_to_overlay_ui()


func _on_OverlayControls_large_ui_requested():
	_switch_to_large_ui()


func _on_OverlayControls_next_song_requested():
	_play_next_song()


func _on_OverlayControls_pause_requested():
	_pause_audio()


func _on_OverlayControls_play_requested():
	_play_audio()


func _on_OverlayControls_previous_song_requested():
	_play_previous_song()


func _on_PlaylistUi_select_library_folder_requested():
	_show_library_dialog_popup()


func _on_move_song_in_playlist_requested(idx: int, relative_idx: int):
	_playlist.move_song(idx, relative_idx)
