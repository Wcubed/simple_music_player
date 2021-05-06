Basic needed features
- x Play song
- x Pause song
- x Load song
- x Show list of songs
- x Select song from list
- x Shuffle
- x Next song button.
- x Load all songs in a directory
  - x and subdirectories

Extra features
- Icons for "Open", "shuffle" etc.
- Previous song button? How would that work with shuffle?
- x Volume slider
- Load an image in the same directory as cover art
- Add a library view.
- Add and remove song library directories.
	- Keep libraries between restarts.
- Order library alphabetically.
- Cache which songs are in a library?
- Cache thumbnails of cover images?
  - Use imagemagick to automatically convert encountered cover images into thumbnails of a format that godot can read.
    that way it doesn't matter what the format of the original image is.
- Change underscores into spaces in song titles, and snip the extension.
- x Shuffle, but only play each song exactly once before repeating.
- When adding songs, make sure we don't add the same song twice.
- x Playlist search
- Show which songs have already been played during shuffle? Or maybe have a separate "library" and "playlist" windows?
  where the playlist window shows the current play queue, which will be shuffled when shuffle is enabled.
- Listen to media keys when the window is focused.
- Listen to media keys when the window is _not_ focused. (Can this be done in gdscript?)
- Allow reordering songs in the playlist
- Allow removing songs from the playlist.