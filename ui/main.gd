extends PanelContainer

var _stream_total_length: float = 0
var _playback_time: float = 0

onready var _playlist := $Playlist
onready var _audio_importer := $AudioImporter

onready var _stream_player := $AudioStreamPlayer
onready var _update_timer := $UpdateTimer

onready var _playback_controls := $VBoxContainer/PlaybackControls

onready var _song_load_dialog := $SongLoadDialog


# Called when the node enters the scene tree for the first time.
func _ready():
	_song_load_dialog.filters = _playlist.FILE_FILTERS


func _show_file_popup():
	_song_load_dialog.popup_centered(Vector2(700, 400))


func _play_next_song():
	_play_song(_playlist.get_next_song_to_play())


func _play_song(song: Object):
	if song == null:
		return
	
	var audio_stream: AudioStream = _audio_importer.loadfile(song.path)
	_stream_player.stream = audio_stream
	_stream_total_length = audio_stream.get_length()
	_playback_time = 0
	
	_playback_controls.update_song_title(song.title)
	_playback_controls.update_total_time(_stream_total_length)
	_playback_controls.update_time_playing(_playback_time)
	
	_play_audio()


func _play_audio():
	if _stream_player.stream == null:
		call_deferred("_play_next_song")
		return
	
	_update_timer.start()
	_stream_player.play(_playback_time)
	
	_playback_controls.update_paused(false)


func _pause_audio():
	if _stream_player.stream == null:
		return
	
	_update_timer.stop()
	_stream_player.stop()
	
	_playback_controls.update_paused(true)


func _audio_finished():
	_play_next_song()


func _seek_timecode(seconds: float):
	if _stream_player.stream == null:
		return
	_playback_time = seconds
	
	_stream_player.seek(_playback_time)
	
	_playback_controls.update_time_playing(_playback_time)


func _on_UpdateTimer_timeout():
	_playback_time = _stream_player.get_playback_position()
	_playback_controls.update_time_playing(_playback_time)


func _unhandled_key_input(event):
	if event.is_action_pressed("ui_right"):
		_seek_timecode(_stream_player.get_playback_position() + 10)
		get_tree().set_input_as_handled()
		
	elif event.is_action_pressed("ui_left"):
		_seek_timecode(_stream_player.get_playback_position() - 10)
		get_tree().set_input_as_handled()


func _on_PlaybackControls_pause_requested():
	_pause_audio()


func _on_PlaybackControls_play_requested():
	_play_audio()


func _on_PlaybackControls_seek_requested(seconds: float):
	_seek_timecode(seconds)



func _on_PlaybackControls_open_file_requested():
	_show_file_popup()


func _on_AudioStreamPlayer_finished():
	_audio_finished()


func _on_SongLoadDialog_file_selected(path: String):
	_playlist.add_song(path)


func _on_SongLoadDialog_files_selected(paths: Array):
	_playlist.add_songs(paths)


func _on_SongLoadDialog_dir_selected(dir: String):
	_playlist.add_songs_from_directory(dir)
