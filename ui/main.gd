extends PanelContainer


onready var _stream_player := $AudioStreamPlayer
onready var _update_timer := $UpdateTimer

onready var _total_time_label := find_node("TotalTimeLabel")
onready var _current_time_label := find_node("CurrentTimeLabel")
onready var _progress_bar := find_node("ProgressBar")
onready var _play_pause_button := find_node("PlayPauseButton")


var _stream_length_seconds := 0.0
var _progress_seconds := 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	var audio_stream: AudioStream = load("res://test.ogg")
	_stream_length_seconds = audio_stream.get_length()
	
	_stream_player.stream = audio_stream
	
	_total_time_label.text = _seconds_to_time_string(_stream_length_seconds)
	_current_time_label.text = _seconds_to_time_string(0)
	_progress_bar.max_value = _stream_length_seconds


func _play_audio():
	_update_timer.start()
	_stream_player.play(_progress_seconds)
	
	_play_pause_button.text = "||"


func _pause_audio():
	_update_timer.stop()
	_stream_player.stop()
	
	_play_pause_button.text = ">"


func _seconds_to_time_string(seconds: float) -> String:
	var hours := floor(seconds / 3600)
	seconds -= hours * 3600
	var minutes := floor(seconds / 60)
	seconds -= minutes * 60
	
	return "%d:%02d:%02d" % [hours, minutes, seconds]


func _seek_to_current_mouse_position():
	var x: int = _progress_bar.get_local_mouse_position().x
	var max_x: int = _progress_bar.rect_size.x
	
	_progress_seconds = (x * _stream_length_seconds) / max_x
	_progress_seconds = clamp(_progress_seconds, 0, _stream_length_seconds)
	
	_stream_player.seek(_progress_seconds)
	_update_ui_to_timecode(_progress_seconds)


func _update_ui_to_timecode(seconds: float):
	_current_time_label.text = _seconds_to_time_string(_progress_seconds)
	_progress_bar.value = _progress_seconds


func _on_UpdateTimer_timeout():
	_progress_seconds = _stream_player.get_playback_position()
	_update_ui_to_timecode(_progress_seconds)


func _on_ProgressBar_gui_input(event: InputEvent):
	if event.is_action_pressed("ui_seek_to_time"):
		_seek_to_current_mouse_position()
	elif event is InputEventMouseMotion and Input.is_action_pressed("ui_seek_to_time"):
		_seek_to_current_mouse_position()


func _on_PlayPauseButton_pressed():
	if _stream_player.playing:
		_pause_audio()
	else:
		_play_audio()
