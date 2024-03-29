extends HBoxContainer

signal play_requested()
signal pause_requested()
signal next_song_requested()
signal previous_song_requested()

signal seek_requested(seconds)
# Volume is in range [0, 1]
signal volume_change_requested(new_volume)
signal infinite_playlist_button_toggled(new_state)
signal overlay_ui_requested()

export(Texture) var _volume_high = preload("resources/icons/icon_volume_high.svg")
export(Texture) var _volume_mid = preload("resources/icons/icon_volume_mid.svg")
export(Texture) var _volume_low = preload("resources/icons/icon_volume_low.svg")

onready var _song_cover_image := $SongCoverImage

onready var _time_playing := $VBoxContainer/TopContainer/TimePlayingLabel
onready var _total_time := $VBoxContainer/TopContainer/TotalTimeLabel
onready var _song_progress := $VBoxContainer/TopContainer/SongProgress

onready var _playback_buttons := $VBoxContainer/BottomContainer/PlaybackButtons
onready var _infinite_playlist_button := $VBoxContainer/BottomContainer/InfinitePlaylistButton
onready var _song_title := $VBoxContainer/BottomContainer/SongTitleLabel

onready var _volume_icon := $VBoxContainer/BottomContainer/VolumeIcon
onready var _volume_slider := $VBoxContainer/BottomContainer/VolumeSlider


# Called when the node enters the scene tree for the first time.
func _ready():
	update_time_playing(0)


func is_infinite_playlist_enabled() -> bool:
	return _infinite_playlist_button.pressed


func update_time_playing(seconds: float):
	seconds = clamp(seconds, 0, _song_progress.max_value)
	_time_playing.text = _seconds_to_time_string(seconds)
	_song_progress.value = seconds


func update_total_time(seconds: float):
	seconds = max(seconds, 0)
	_total_time.text = _seconds_to_time_string(seconds)
	_song_progress.max_value = seconds


func update_paused(paused: bool):
	_playback_buttons.update_paused(paused)


func update_cover_image(image: ImageTexture):
	_song_cover_image.texture = image


func update_song_title(title: String):
	_song_title.text = title


func update_volume(volume: float):
	_volume_slider.value = volume
	
	if volume < 0.3:
		_volume_icon.texture = _volume_low
	elif volume >= 0.3 && volume < 0.7:
		_volume_icon.texture = _volume_mid
	else:
		_volume_icon.texture = _volume_high


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


func _on_SongProgress_gui_input(event: InputEvent):
	if event.is_action_pressed("ui_seek_to_time"):
		_seek_to_current_mouse_position()
	elif event is InputEventMouseMotion and Input.is_action_pressed("ui_seek_to_time"):
		_seek_to_current_mouse_position()


func _on_VolumeSlider_value_changed(value: float):
	emit_signal("volume_change_requested", value)


func _on_InfinitePlaylistButton_toggled(button_pressed: bool):
	emit_signal("infinite_playlist_button_toggled", button_pressed)


func _on_PlaybackButtons_next_song_requested():
	emit_signal("next_song_requested")


func _on_PlaybackButtons_previous_song_requested():
	emit_signal("previous_song_requested")


func _on_PlaybackButtons_play_requested():
	emit_signal("play_requested")


func _on_PlaybackButtons_pause_requested():
	emit_signal("pause_requested")


func _on_OverlayUIButton_pressed():
	emit_signal("overlay_ui_requested")
