extends HBoxContainer

signal selected_by_pointer(playlist_index)
signal remove_button_pressed(playlist_index)
signal move_entry_requested(playlist_index, relative_idx)

const PLAYING_COLOR = Color(0.3, 1.0, 0.3)
const NOT_PLAYING_COLOR = Color(0.9, 0.9, 0.9)

var _song_id := -1

onready var _cover_image := $CoverImage
onready var _title := $Title
onready var _move_handle := $PlaylistMoveHandle
onready var _remove_button := $RemoveButton


# Called when the node enters the scene tree for the first time.
func _ready():
	show_currently_playing(false)
	
	hide_controls()


func show_controls():
	_move_handle.modulate.a = 1
	_remove_button.modulate.a = 1

func hide_controls():
	_move_handle.modulate.a = 0
	_remove_button.modulate.a = 0
	
	_remove_button.flat = true

func get_title():
	return _title.text


func show_song(song_id: int, song: Object):
	_song_id = song_id
	_title.text = song.title

	if song.image != null:
		update_image(song.image)


func update_image(image: ImageTexture):
	_cover_image.texture = image


func show_currently_playing(playing: bool):
	if playing:
		_title.set("custom_colors/font_color", PLAYING_COLOR)
	else:
		_title.set("custom_colors/font_color", NOT_PLAYING_COLOR)


func _on_PlaylistEntry_gui_input(event: InputEvent):
	if event.is_action_released("ui_pointer_select"):
		emit_signal("selected_by_pointer", get_index())

func _on_library_cover_image_loaded(song_id: int, image: ImageTexture):
	if song_id == _song_id:
		update_image(image)


func _on_RemoveButton_pressed():
	emit_signal("remove_button_pressed", get_index())


func _on_PlaylistMoveHandle_gui_input(event: InputEvent):
	if event is InputEventMouseMotion:
		var global_mouse_pos: Vector2 = OS.window_position + event.position
		
		if Input.is_action_pressed("ui_window_drag_control"):
			var local_pos := get_local_mouse_position()
			if local_pos.y < 0 or local_pos.y >= rect_size.y:
				# At this moment 2022-04-10 all the playlist entries have
				# the same height. So we can calculate how much we want to go
				# up or down.
				var move = floor(local_pos.y / rect_size.y)
				emit_signal("move_entry_requested", get_index(), move)
			

func _on_PlaylistEntry_mouse_entered():
	show_controls()

func _on_PlaylistEntry_mouse_exited():
	hide_controls()


func _on_RemoveButton_mouse_entered():
	show_controls()
	_remove_button.flat = false

func _on_RemoveButton_mouse_exited():
	_remove_button.flat = true


func _on_PlaylistMoveHandle_mouse_entered():
	show_controls()


func _on_PlaylistMoveHandle_mouse_exited():
	hide_controls()
