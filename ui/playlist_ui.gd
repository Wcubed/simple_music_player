extends VBoxContainer

# Emitted when the user requests the song at a specific index in the playlist
# is played.
signal play_song_by_index_requested(idx)
# Emitted when the user wants to remove a song from the playlist.
signal remove_song_by_index_requested(idx)
signal add_song_requested()


var PlaylistEntry := preload("playlist_entry.tscn")
var _libary: Node = null

onready var _scroll_container := $ScrollContainer
onready var _container := $ScrollContainer/PlaylistContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# The UI needs to be able to access the library to properly display the songs.
# This needs to be called before anything else on this node.
func set_library(library_node: Node):
	_libary = library_node


# Call when a song is added to the playlist.
# The id indicates which song to add, the idx indicates where to add it.
func _on_playlist_song_added(song_id: int, playlist_idx: int):
	var song: Object = _libary.get_song_by_id(song_id)
	if song == null:
		return
	
	var entry := PlaylistEntry.instance()
	
	if playlist_idx < _container.get_child_count():
		var node_to_insert_below := _container.get_child(playlist_idx)
		_container.add_child_below_node(entry, node_to_insert_below)
	else:
		_container.add_child(entry)
	
	entry.show_song(song_id, song)
	
	entry.connect("selected_by_pointer", self, \
		"_on_entry_selected_by_pointer", [playlist_idx])
	entry.connect("remove_button_pressed", self, \
		"_on_entry_remove_button_pressed", [playlist_idx])
	_libary.connect("cover_image_loaded", entry, "_on_library_cover_image_loaded")


func _on_playlist_song_removed(playlist_idx: int):
	var child := _container.get_child(playlist_idx)
	_container.remove_child(child)


func _on_playlist_currently_playing_updated(song_idx: int):
	for entry in _container.get_children():
		entry.show_currently_playing(false)
	
	var current_playing := _container.get_child(song_idx)
	current_playing.show_currently_playing(true)
	
	_scroll_to_entry(current_playing)


# Scrolls the container so that the given song entry is visible.
func _scroll_to_entry(entry: Control):
	if entry == null:
		return
	
	var scrollbar: VScrollBar = _scroll_container.get_v_scrollbar()
	if scrollbar.page == 0:
		return
	
	var min_visible_y := scrollbar.value
	var max_visible_y := scrollbar.value + scrollbar.page
	
	var entry_y: float = entry.rect_position.y
	var entry_height: float = entry.rect_size.y
	
	if entry_y < min_visible_y:
		scrollbar.value = entry_y
	elif entry_y + entry_height > max_visible_y:
		scrollbar.value = entry_y - scrollbar.page + entry_height


func _on_entry_selected_by_pointer(idx: int):
	emit_signal("play_song_by_index_requested", idx)

func _on_entry_remove_button_pressed(idx: int):
	emit_signal("remove_song_by_index_requested", idx)


func _on_AddSongButton_pressed():
	emit_signal("add_song_requested")

