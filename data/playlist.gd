extends Node

# The playlist_idx is where in the playlist this song was added.
signal song_added(song_id, playlist_idx)
signal song_removed(playlist_idx)
signal currently_playing_updated(song_idx)

# The playlist keeps track of which songs to play from the library
# and in what order.

# How many songs there will be at minimum between the current song and the
# end of an infinite playlist.
const INFINITE_PLAYLIST_NEXT_SONGS_BUFFER := 4
# How many songs to keep as "history" when running an infinite playlist.
const INFINITE_PLAYLIST_MAX_HISTORY := 4

# The playlist can be "infinite" in which case it will append a
# new random song to the playlist every time it hits the last song.
# While ensuring to play every song at least once before repeating.
var _infinite_playlist := false

# Keeps the song ids of the playlist, in the order that they will be played / 
# have been played.
var _playlist := []

# Which of the songs in the `playlist` array is currently playing.
# If this is an invalid index, the playlist will simply start at the beginning.
var _current_song_idx: int = -1

# All the song id's available in the library.
# This is what the `songs_left_till_library_repeat` is filled with when it is
# empty.
var _library_song_ids := {}
# Has id's of all the songs in the library (with 'null' values. it's a hash-set)
# When a random song is needed it is selected from here.
# When a song is played, it is removed from the set.
# This guarantees that all songs will be played at least once before the library
# repeats.
# Re-fills from the `library_song_ids` when empty.
var _songs_left_till_library_repeat := {}

func _ready():
	# Initialize the pseudorandom seed to make sure shuffling is different
	# each time.
	randomize()


func set_infinite(infinite: bool):
	_infinite_playlist = infinite


# Returns -1 if there is no current song.
func get_current_song_id() -> int:
	if _playlist.empty():
		return -1
	return _playlist[_current_song_idx]


# Returns the index of the currently playing song.
func get_current_song_idx() -> int:
	return _current_song_idx


# Returns the id of the next song to play, and assumes it will be played.
# Returns `-1` if the playlist is empty and not requested to be infinite.
func select_next_song() -> int:
	return select_song_by_index(_current_song_idx + 1)


# Returns the id of the previous song in the playlist, and assumes it will
# be played.
# Wraps around if it reaches the top.
# Returns `-1` if the playlist is empty and not infinite.
func select_previous_song():
	return select_song_by_index(_current_song_idx - 1)

# Returns the id of the song at a specific index in the playlist.
# Assumes that song is now going to be played.
# Negative indexes will wrap to the end of the playlist.
# Returns -1 if the playlist is empty and not infinite.
func select_song_by_index(idx: int):
	if _library_song_ids.empty() || _playlist.empty() && !_infinite_playlist:
		return -1
	
	if idx < 0:
		idx = _playlist.size() + idx
	
	if _infinite_playlist:
		# The infinite playlist grows before it reaches the end.
		# The end of the list is always at least a certain amount of songs
		# ahead of the current song.
		while _playlist.size() <= idx + INFINITE_PLAYLIST_NEXT_SONGS_BUFFER:
			_append_random_song()
		
		# The infinite playlist only keeps a certain amount of songs behind
		# the current song.
		while idx > INFINITE_PLAYLIST_MAX_HISTORY:
			remove_song_at_index(0)
			idx -= 1
	
	idx = idx % _playlist.size()
	_current_song_idx = idx
	
	_songs_left_till_library_repeat.erase(_current_song_idx)
	emit_signal("currently_playing_updated", idx)
	return _playlist[idx]


# Call when the song library acquires new songs. This makes sure the
# infinite playlist randomizer is up-to-date.
func _on_songs_added_to_library(new_song_ids: Array):
	for id in new_song_ids:
		_library_song_ids[id] = null
		_songs_left_till_library_repeat[id] = null


# Call when the song library loses songs.
func _on_songs_removed_from_library(removed_song_ids: Array):
	for id in removed_song_ids:
		_library_song_ids.erase(id)
		_songs_left_till_library_repeat.erase(id)
		
		# Erase the song from the playlist itself. 
		# It might appear multiple times.
		var find_idx := _playlist.find(id)
		while find_idx != -1:
			_playlist.remove(find_idx)
			find_idx = _playlist.find(id, find_idx)


# Is random, except for that it will play the whole library before repeating.
func _append_random_song():
	if _songs_left_till_library_repeat.empty():
		_refill_songs_left_till_library_repeat()
	
	var pick_idx: int = randi() % _songs_left_till_library_repeat.size()
	var id: int = _songs_left_till_library_repeat.keys()[pick_idx]
	append_song_to_playlist(id)


func append_song_to_playlist(song_id: int):
	_playlist.append(song_id)
	emit_signal("song_added", song_id, _playlist.size() - 1)


func remove_song_at_index(song_index: int):
	_playlist.remove(song_index)
	emit_signal("song_removed", song_index)

func _refill_songs_left_till_library_repeat():
	_songs_left_till_library_repeat = _library_song_ids.duplicate()
