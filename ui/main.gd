extends PanelContainer


onready var _stream_player := $AudioStreamPlayer
onready var _seconds_timer := $SecondsTimer

onready var _total_time_label := find_node("TotalTimeLabel")
onready var _current_time_label := find_node("CurrentTimeLabel")
onready var _seek_slider := find_node("SeekSlider")


var _stream_length_seconds := 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	var audio_stream: AudioStream = load("res://test.ogg")
	_stream_length_seconds = audio_stream.get_length()
	
	_stream_player.stream = audio_stream
	_stream_player.play()
	
	_total_time_label.text = _seconds_to_time_string(_stream_length_seconds)
	_current_time_label.text = _seconds_to_time_string(0)
	_seek_slider.max_value = _stream_length_seconds
	
	_seconds_timer.start()


func _seconds_to_time_string(seconds: float) -> String:
	var hours := floor(seconds / 3600)
	seconds -= hours * 3600
	var minutes := floor(seconds / 60)
	seconds -= minutes * 60
	
	return "%d:%02d:%02d" % [hours, minutes, seconds]


func _on_SecondsTimer_timeout():
	var playback_seconds: float = _stream_player.get_playback_position()
	_current_time_label.text = _seconds_to_time_string(playback_seconds)
	_seek_slider.value = playback_seconds
