extends HBoxContainer

signal play_requested()
signal pause_requested()
signal next_song_requested()
signal previous_song_requested()

signal large_ui_requested()

onready var _playback_buttons := $PlaybackButtons
onready var _song_title := $SongTitleLabel


func _ready():
	pass


func update_song_title(title: String):
	_song_title.text = title


func update_paused(paused: bool):
	_playback_buttons.update_paused(paused)


func _on_PlaybackButtons_next_song_requested():
	emit_signal("next_song_requested")


func _on_PlaybackButtons_previous_song_requested():
	emit_signal("previous_song_requested")


func _on_PlaybackButtons_play_requested():
	emit_signal("play_requested")


func _on_PlaybackButtons_pause_requested():
	emit_signal("pause_requested")


func _on_LargeUIButton_pressed():
	emit_signal("large_ui_requested")
