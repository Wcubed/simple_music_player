tool
extends EditorPlugin

# So we can find our controls again, if we loose track of it.
# For example because this script got reloaded with the plugin enabled.
const CONTROLS_NAME: = "__Quick_Export_Controls__"

var controls_scene: PackedScene = preload("./ui/quick_export_controls.tscn")

var controls: Node = null

func _enter_tree():
	# Check if this is a second activation of this plugin.
	get_controls()
	
	if controls == null:
		controls = controls_scene.instance()
		controls.name = CONTROLS_NAME
		add_control_to_container(CONTAINER_TOOLBAR, controls)
	
	controls.connect("pressed", self, "_on_export_button_pressed")
	
	print("%s plugin activated" % get_plugin_name())


func _exit_tree():
	get_controls()
	remove_control_from_container(CONTAINER_TOOLBAR, controls)
	
	controls.queue_free()
	
	print("%s plugin deactivated" % get_plugin_name())


# Makes sure we have a reference to our controls.
func get_controls():
	if controls == null:
		# The script got reinstantiated, get a reference to the controls again.
		controls = get_tree().root.find_node(CONTROLS_NAME + "*", true, false)


func get_plugin_name() -> String:
	return "Quick Export"

func _on_export_button_pressed():
	# First we get the export dialog.
	var export_dialog: Node = null
	# It is one of the direct children of the editor base control.
	# TODO: might break at any time.
	for child in get_editor_interface().get_base_control().get_children():
		if child.get_class() == "ProjectExportDialog":
			export_dialog = child
			break
	
	var export_all_dialog: ConfirmationDialog = null
	for child in export_dialog.get_children():
		if child.get_class() == "ConfirmationDialog":
			# TODO: this might break at any time.
			if child.window_title == "Export All":
				export_all_dialog = child
				# Found it!
				break
	
	# The "debug" button is in an HBoxContainer.
	for child in export_all_dialog.get_children():
		if child.get_class() == "HBoxContainer":
			# The button has "Debug" as text.
			for sub_child in child.get_children():
				if sub_child.get_class() == "Button":
					if sub_child.text == "Debug":
						print("Quick export. If nothing happens, there are no export presets. Add one via \"Project->Export...\"")
						# Simulate pressing the button.
						sub_child.emit_signal("pressed")
						break
			break
