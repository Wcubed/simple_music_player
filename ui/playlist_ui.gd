extends VBoxContainer


signal play_song_by_index_requested(idx)
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
	
	entry.show_song(song)
	
	entry.connect("selected_by_pointer", self, \
		"_on_entry_pointer_selected_by_pointer", [_container.get_child_count() - 1])


func _on_playlist_currently_playing_updated(current_idx: int, previous_idx: int):
	if previous_idx >= 0:
		_container.get_child(previous_idx).show_currently_playing(false)
	
	var current_playing := _container.get_child(current_idx)
	current_playing.show_currently_playing(true)



func _on_entry_pointer_selected_by_pointer(idx: int):
	emit_signal("play_song_by_index_requested", idx)


func _on_AddSongButton_pressed():
	emit_signal("add_song_requested")
