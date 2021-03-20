extends VBoxContainer


signal play_song_by_index_requested(idx)


var PlaylistEntry := preload("playlist_entry.tscn")


var _playlist: Node = null


onready var _container := $ScrollContainer/PlaylistContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_playlist(playlist: Node):
	if _playlist != null:
		_playlist.disconnect("playlist_songs_updated", self, "_on_playlist_songs_updated")
		_playlist.disconnect("currently_playing_updated", self, "_on_playlist_currently_playing_updated")
	
	_playlist = playlist
	_playlist.connect("playlist_songs_updated", self, "_on_playlist_songs_updated")
	_playlist.connect("currently_playing_updated", self, "_on_playlist_currently_playing_updated")


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
	_container.get_child(current).show_currently_playing(true)


func _on_entry_pointer_selected_by_pointer(idx: int):
	emit_signal("play_song_by_index_requested", idx)
