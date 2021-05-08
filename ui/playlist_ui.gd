extends VBoxContainer

# Emitted when the user requests the song at a specific index in the playlist
# is played.
signal play_song_by_index_requested(idx)
# Emitted when the user wants to remove a song from the playlist.
signal remove_song_by_index_requested(idx)
# User requested to open the file browser to add songs to the library.
signal add_song_to_library_requested()
# User requested to add a specific song to the playlist.
# This is the song id as listed in the library, not the playlist index.
signal add_song_to_playlist_requested(id)

# How many items the song search popup will display before putting 
# elipsis as the last item. This prevents the popup from growing 
# taller than the window and obscuring the search bar.
const MAX_ITEMS_IN_SEARCH_POPUP := 20
const MAX_ITEMS_IN_SEARCH_END_ITEM := "..."


var PlaylistEntry := preload("playlist_entry.tscn")
var _libary: Node = null

onready var _scroll_container := $ScrollContainer
onready var _container := $ScrollContainer/PlaylistContainer

onready var _search_library_entry := $HBoxContainer/SearchLibraryEntry
onready var _clear_search_button := $HBoxContainer/ClearSearchButton
onready var _search_popup := $HBoxContainer/SearchLibraryEntry/SearchPopup

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# The UI needs to be able to access the library to properly display the songs.
# This needs to be called before anything else on this node.
func set_library(library_node: Node):
	_libary = library_node


# Call when a song is added to the playlist.
# The id indicates which song to add, the idx indicates after which location
# to insert it.
func _on_playlist_song_added(song_id: int, playlist_idx: int):
	var song: Object = _libary.get_song_by_id(song_id)
	if song == null:
		return
	
	var entry := PlaylistEntry.instance()
	
	if playlist_idx < _container.get_child_count():
		var node_to_insert_below: Control = _container.get_child(playlist_idx)
		_container.add_child_below_node(node_to_insert_below, entry)
	else:
		_container.add_child(entry)
	
	entry.show_song(song_id, song)
	
	entry.connect("selected_by_pointer", self, \
		"_on_entry_selected_by_pointer")
	entry.connect("remove_button_pressed", self, \
		"_on_entry_remove_button_pressed")
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


func clear_library_search():
	_search_library_entry.text = ""
	_clear_search_button.hide()
	_search_popup.hide()
	_search_popup.clear()


func show_library_search(search_text: String):
	_clear_search_button.show()
	_search_popup.clear()
	
	var search_results: Dictionary = _libary.search_songs_by_title(search_text)
	
	var count := 0
	for id in search_results.keys():
		var song: Object = search_results[id]
		_search_popup.add_item(song.title, id)
		
		count += 1
		# Prevent the search popup from growing too large.
		if count >= MAX_ITEMS_IN_SEARCH_POPUP:
			_search_popup.add_item("...")
			break
	
	var popup_x: float = _search_library_entry.rect_global_position.x
	var popup_y: float = _search_library_entry.rect_global_position.y + \
		_search_library_entry.rect_size.y
	var popup_width: float = _search_library_entry.rect_size.x
	
	_search_popup.popup(Rect2(popup_x, popup_y, popup_width, 1))


func _on_entry_selected_by_pointer(idx: int):
	emit_signal("play_song_by_index_requested", idx)


func _on_entry_remove_button_pressed(idx: int):
	emit_signal("remove_song_by_index_requested", idx)


func _on_AddSongButton_pressed():
	emit_signal("add_song_to_library_requested")


func _on_ClearSearchButton_pressed():
	clear_library_search()


func _on_SearchLibraryEntry_text_changed(search_string: String):
	if search_string == "":
		clear_library_search()
	else:
		show_library_search(search_string)


func _on_SearchLibraryEntry_gui_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		clear_library_search()


func _on_SearchLibraryEntry_text_entered(new_text: String):
	# On pressing enter, we add the topmost song from the search 
	# results to the playlist.
	if _search_popup.get_item_count() > 0:
		var song_id: int = _search_popup.get_item_id(0)
		emit_signal("add_song_to_playlist_requested", song_id)
		
		clear_library_search()


func _on_SearchPopup_index_pressed(index: int):
	if _search_popup.get_item_text(index) != MAX_ITEMS_IN_SEARCH_END_ITEM:
		emit_signal("add_song_to_playlist_requested", _search_popup.get_item_id(index))
		
		clear_library_search()

