extends VBoxContainer

signal play_requested()
signal pause_requested()
signal seek_requested(seconds)

var _paused := true

onready var _time_playing := $TopContainer/TimePlayingLabel
onready var _total_time := $TopContainer/TotalTimeLabel
onready var _song_progress := $TopContainer/SongProgress

onready var _play_pause_button := $BottomContainer/PlayPauseButton
onready var _song_title := $BottomContainer/SongTitleLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	update_time_playing(0)
	update_paused(true)


func update_time_playing(seconds: float):
	seconds = clamp(seconds, 0, _song_progress.max_value)
	_time_playing.text = _seconds_to_time_string(seconds)
	_song_progress.value = seconds


func update_total_time(seconds: float):
	seconds = max(seconds, 0)
	_total_time.text = _seconds_to_time_string(seconds)
	_song_progress.max_value = seconds


func update_paused(paused: bool):
	_paused = paused
	if _paused:
		_play_pause_button.text = ">"
	else:
		_play_pause_button.text = "||"


func _seconds_to_time_string(seconds: float) -> String:
	var hours := floor(seconds / 3600)
	seconds -= hours * 3600
	var minutes := floor(seconds / 60)
	seconds -= minutes * 60
	
	return "%d:%02d:%02d" % [hours, minutes, seconds]


func _seek_to_current_mouse_position():
	var x: int = _song_progress.get_local_mouse_position().x
	var max_x: int = _song_progress.rect_size.x
	
	var seek: float = (x * _song_progress.max_value) / max_x
	seek = clamp(seek, 0, _song_progress.max_value)
	
	emit_signal("seek_requested", seek)


func _on_PlayPauseButton_pressed():
	if _paused:
		emit_signal("play_requested")
	else:
		emit_signal("pause_requested")


func _on_SongProgress_gui_input(event: InputEvent):
	if event.is_action_pressed("ui_seek_to_time"):
		_seek_to_current_mouse_position()
	elif event is InputEventMouseMotion and Input.is_action_pressed("ui_seek_to_time"):
		_seek_to_current_mouse_position()
