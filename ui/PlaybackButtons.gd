extends HBoxContainer

signal play_requested()
signal pause_requested()
signal next_song_requested()
signal previous_song_requested()

export(Texture) var _play_icon = preload("resources/icons/icon_play.svg")
export(Texture) var _pause_icon = preload("resources/icons/icon_pause.svg")

var _paused := true

onready var _play_pause_button := $PlayPauseButton

func _ready():
	update_paused(true)


func update_paused(paused: bool):
	_paused = paused
	if _paused:
		_play_pause_button.icon = _play_icon
	else:
		_play_pause_button.icon = _pause_icon


func _on_PlayPauseButton_pressed():
	if _paused:
		emit_signal("play_requested")
	else:
		emit_signal("pause_requested")

func _on_NextSongButton_pressed():
	emit_signal("next_song_requested")


func _on_PreviousSongButton_pressed():
	emit_signal("previous_song_requested")
