extends PanelContainer


onready var _stream_player := $AudioStreamPlayer
onready var _update_timer := $UpdateTimer

onready var _total_time_label := find_node("TotalTimeLabel")
onready var _current_time_label := find_node("CurrentTimeLabel")
onready var _progress_bar := find_node("ProgressBar")


var _stream_length_seconds := 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	var audio_stream: AudioStream = load("res://test.ogg")
	_stream_length_seconds = audio_stream.get_length()
	
	_stream_player.stream = audio_stream
	_stream_player.play()
	
	_total_time_label.text = _seconds_to_time_string(_stream_length_seconds)
	_current_time_label.text = _seconds_to_time_string(0)
	_progress_bar.max_value = _stream_length_seconds
	
	_update_timer.start()


func _seconds_to_time_string(seconds: float) -> String:
	var hours := floor(seconds / 3600)
	seconds -= hours * 3600
	var minutes := floor(seconds / 60)
	seconds -= minutes * 60
	
	return "%d:%02d:%02d" % [hours, minutes, seconds]


func _seek_to_current_mouse_position():
	var x: int = _progress_bar.get_local_mouse_position().x
	var max_x: int = _progress_bar.rect_size.x
	
	_stream_player.seek((x * _stream_length_seconds) / max_x)


func _on_UpdateTimer_timeout():
	var playback_seconds: float = _stream_player.get_playback_position()
	_current_time_label.text = _seconds_to_time_string(playback_seconds)
	_progress_bar.value = playback_seconds


func _on_ProgressBar_gui_input(event: InputEvent):
	if event.is_action_pressed("ui_seek_to_time"):
		_seek_to_current_mouse_position()
	elif event is InputEventMouseMotion and Input.is_action_pressed("ui_seek_to_time"):
		_seek_to_current_mouse_position()
