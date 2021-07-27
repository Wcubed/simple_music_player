extends Object

var path: String
var title: String
var image: ImageTexture

func _init(new_path: String, new_title: String, new_image: ImageTexture = null):
	path = new_path
	title = new_title
	image = new_image
