tool
extends EditorPlugin

var _dock_instance : Control

const STORED_SESSIONS_PATH : String = "res://.tracked-sessions.json"

func _enter_tree() -> void:
	_dock_instance = load("res://addons/time-tracker/TrackerDock.tscn").instance()
	_dock_instance.name = "TimeTracker"
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, _dock_instance)
	
	_load_sessions()
	
	# Try to find controls immediately (it will fail if not ready yet).
	_on_editor_base_ready()
	# Also connect to the ready signal, so that it is correctly detected then.
	var editor_base = get_editor_interface().get_base_control()
	editor_base.connect("ready", self, "_on_editor_base_ready")
	# And connect to the signal that will trigger when a user actually interacts with top buttons.
	connect("main_screen_changed", self, "_on_main_screen_changed")

func _exit_tree() -> void:
	_store_sessions()
	
	remove_control_from_docks(_dock_instance)
	_dock_instance.queue_free()

func _load_sessions() -> void:
	var file = File.new()
	if (!file.file_exists(STORED_SESSIONS_PATH)):
		return
	
	var error = file.open(STORED_SESSIONS_PATH, File.READ)
	if (error != OK):
		printerr("Failed to open tracked sessions file for reading: Error code " + str(error))
		return
	
	var stored_string = file.get_as_text()
	var parse_result = JSON.parse(stored_string)
	if (parse_result.error != OK):
		printerr("Failed to parse tracked sessions: Error code " + str(parse_result.error))
	else:
		var stored_sessions = parse_result.result
		if (stored_sessions is Array && stored_sessions.size() > 0):
			_dock_instance.restore_tracked_sessions(stored_sessions)
	
	file.close()

func _store_sessions() -> void:
	var tracked_sessions = _dock_instance.get_tracked_sessions()
	var stored_string = JSON.print(tracked_sessions, "  ")
	
	var file = File.new()
	var error = file.open(STORED_SESSIONS_PATH, File.WRITE)
	if (error != OK):
		printerr("Failed to open tracked sessions file for writing: Error code " + str(error))
		return
	
	file.store_string(stored_string)
	error = file.get_error()
	if (error != OK):
		printerr("Failed to store tracked sessions: Error code " + str(error))
	
	file.close()

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
