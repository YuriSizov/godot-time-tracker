tool
extends EditorPlugin

var _dock_instance : Control

func _enter_tree() -> void:
	_dock_instance = load("res://addons/time-tracker/TrackerDock.tscn").instance()
	_dock_instance.name = "TimeTracker"
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, _dock_instance)
	
	# Try to find controls immediately (it will fail if not ready yet).
	_on_editor_base_ready()
	# Also connect to the ready signal, so that it is correctly detected then.
	var editor_base = get_editor_interface().get_base_control()
	editor_base.connect("ready", self, "_on_editor_base_ready")
	# And connect to the signal that will trigger when a user actually interacts with top buttons.
	connect("main_screen_changed", self, "_on_main_screen_changed")

func _exit_tree() -> void:
	_dock_instance.queue_free()

func _on_editor_base_ready() -> void:
	var editor_base = get_editor_interface().get_base_control()
	if (!editor_base.is_inside_tree() || editor_base.get_child_count() == 0):
		return
	
	var editor_main_vbox
	for child_node in editor_base.get_children():
		if (child_node.get_class() == "VBoxContainer"):
			editor_main_vbox = child_node
			break
	if (!editor_main_vbox || !is_instance_valid(editor_main_vbox)):
		return
	if (editor_main_vbox.get_child_count() == 0):
		return
	
	var editor_menu_hb
	for child_node in editor_main_vbox.get_children():
		if (child_node.get_class() == "HBoxContainer"):
			editor_menu_hb = child_node
			break
	if (!editor_menu_hb || !is_instance_valid(editor_menu_hb)):
		return
	if (editor_menu_hb.get_child_count() == 0):
		return
	
	var match_counter = 0
	var editor_main_button_vb
	for child_node in editor_menu_hb.get_children():
		if (child_node.get_class() == "HBoxContainer"):
			match_counter += 1
		if (match_counter == 2):
			editor_main_button_vb = child_node
			break
	if (!editor_main_button_vb || !is_instance_valid(editor_main_button_vb)):
		return
	var main_screen_buttons = editor_main_button_vb.get_children()
	
	for button_node in main_screen_buttons:
		if !(button_node is ToolButton):
			continue
		if (button_node.pressed):
			_on_main_screen_changed(button_node.text)
			break

func _on_main_screen_changed(main_screen: String) -> void:
	if (_dock_instance && is_instance_valid(_dock_instance)):
		_dock_instance.set_main_view(main_screen)
