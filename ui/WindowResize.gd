extends VSeparator

var _last_global_mouse_pos = null


func _ready():
	pass

func _on_WindowResize_gui_input(event: InputEvent):
	if event is InputEventMouseMotion:
		var global_mouse_pos: Vector2 = OS.window_position + event.position
		
		if Input.is_action_pressed("ui_window_drag_control") \
				and _last_global_mouse_pos != null:
			var movement = global_mouse_pos - _last_global_mouse_pos
			
			if OS.window_size.x + movement.x >= OS.min_window_size.x:
				OS.window_size.x += movement.x
		
		_last_global_mouse_pos = global_mouse_pos

