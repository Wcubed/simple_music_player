extends VBoxContainer


signal play_song_by_index_requested(idx)
signal add_song_requested()


var PlaylistEntry := preload("playlist_entry.tscn")


var _playlist: Node = null

onready var _search_edit := $HBoxContainer/SearchEdit
onready var _search_clear := $HBoxContainer/ClearButton
onready var _scroll_container := $ScrollContainer
onready var _container := $ScrollContainer/PlaylistContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_playlist(playlist: Node):
	if _playlist != null:
		_playlist.disconnect("playlist_songs_updated", self, "_on_playlist_songs_updated")
		_playlist.disconnect("currently_playing_updated", self, "_on_playlist_currently_playing_updated")
		_playlist.disconnect("cover_image_loaded", self, "_on_playlist_cover_image_loaded")

	_playlist = playlist
	_playlist.connect("playlist_songs_updated", self, "_on_playlist_songs_updated")
	_playlist.connect("currently_playing_updated", self, "_on_playlist_currently_playing_updated")
	_playlist.connect("cover_image_loaded", self, "_on_playlist_cover_image_loaded")


func _on_playlist_songs_updated():
	# TODO: remove old songs.
	var songs: Array = _playlist.get_songs()
	for song in songs:
		var entry := PlaylistEntry.instance()
		_container.add_child(entry)
		entry.connect("selected_by_pointer", self, \
			"_on_entry_pointer_selected_by_pointer", [_container.get_child_count() - 1])

		entry.show_song(song)


func _on_playlist_currently_playing_updated(current: int, previous: int):
	if previous >= 0:
		_container.get_child(previous).show_currently_playing(false)

	var current_playing := _container.get_child(current)
	current_playing.show_currently_playing(true)



func _on_entry_pointer_selected_by_pointer(idx: int):
	emit_signal("play_song_by_index_requested", idx)


func _filter_displayed_songs(match_title: String):
	for entry in _container.get_children():
		var show = true
		if match_title != "":
			show = entry.get_title().findn(match_title) != -1
		entry.visible = show


func _clear_search_edit():
	_search_edit.text = ""
	_search_edit.emit_signal("text_changed", "")


func _on_SearchEdit_text_changed(new_text: String):
	_search_clear.visible = new_text != ""

	_filter_displayed_songs(new_text)


func _on_ClearButton_pressed():
	_clear_search_edit()


func _on_SearchEdit_gui_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		_clear_search_edit()
		get_tree().set_input_as_handled()


func _on_AddSongButton_pressed():
	emit_signal("add_song_requested")


func _on_playlist_cover_image_loaded(idx: int, image: ImageTexture):
	if _container.get_child_count() <= idx:
		return

	_container.get_child(idx).update_image(image)
