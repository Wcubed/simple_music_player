extends HBoxContainer

const PLAYING_COLOR = Color(0.3, 1.0, 0.3)
const NOT_PLAYING_COLOR = Color(0.9, 0.9, 0.9)


onready var _title := $Title


# Called when the node enters the scene tree for the first time.
func _ready():
	show_currently_playing(false)


func show_song(song: Object):
	_title.text = song.title


func show_currently_playing(playing: bool):
	if playing:
		_title.set("custom_colors/font_color", PLAYING_COLOR)
	else:
		_title.set("custom_colors/font_color", NOT_PLAYING_COLOR)
