extends PanelContainer


const FILE_FILTERS := ["*.mp3", "*.wav", "*.ogg"]

var _play_progress := 0.0


onready var _stream_player := $AudioStreamPlayer
onready var _update_timer := $UpdateTimer

onready var _playback_controls := $PlaybackControls

onready var _file_dialog := $FileDialog


# Called when the node enters the scene tree for the first time.
func _ready():
	_file_dialog.filters = FILE_FILTERS


func _show_file_popup():
	_file_dialog.popup_centered(Vector2(400, 400))


func _play_audio_file(path: String):
	var audio_stream: AudioStream = load(path)
	_stream_player.stream = audio_stream
	
	_playback_controls.update_song_title(path)
	_playback_controls.update_total_time(audio_stream.get_length())
	_playback_controls.update_time_playing(0)
	
	_play_audio()


func _play_audio():
	if _stream_player.stream == null:
		return
	
	_update_timer.start()
	_stream_player.play(_play_progress)
	
	_playback_controls.update_paused(false)


func _pause_audio():
	if _stream_player.stream == null:
		return
	
	_update_timer.stop()
	_stream_player.stop()
	
	_playback_controls.update_paused(true)


func _seek_timecode(seconds: float):
	if _stream_player.stream == null:
		return
	
	_play_progress = seconds
	_stream_player.seek(_play_progress)
	_playback_controls.update_time_playing(_play_progress)


func _on_UpdateTimer_timeout():
	_play_progress = _stream_player.get_playback_position()
	_playback_controls.update_time_playing(_play_progress)


func _unhandled_key_input(event):
	if event.is_action_pressed("ui_right"):
		_seek_timecode(_play_progress + 10)
		get_tree().set_input_as_handled()
		
	elif event.is_action_pressed("ui_left"):
		_seek_timecode(_play_progress - 10)
		get_tree().set_input_as_handled()


func _on_PlaybackControls_pause_requested():
	_pause_audio()


func _on_PlaybackControls_play_requested():
	_play_audio()


func _on_PlaybackControls_seek_requested(seconds: float):
	_seek_timecode(seconds)


func _on_FileDialog_file_selected(path: String):
	_play_audio_file(path)


func _on_PlaybackControls_open_file_requested():
	_show_file_popup()
