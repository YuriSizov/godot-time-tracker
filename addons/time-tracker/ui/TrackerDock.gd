@tool
extends MarginContainer

signal sessions_changed()
signal save_requested(file_path)
signal restore_requested(file_path)

# Public properties
var editor_plugin : EditorPlugin

# Private properties
var _active_tracking : bool = false
var _tracker_started : int = 0
var _tracker_elapsed : float = 0.0

var _tracker_main_view : String = ""
var _tracker_main_view_started : int = 0
var _tracker_sections : Array = []

var _paused_tracking : bool = false
var _paused_started : int = 0

# Utils
const _PluginUtils := preload("../utils/PluginUtils.gd")

# Scene references
@onready var tracker_session = preload("./TrackerSession.tscn")

# Node references
@onready var status_label : Label = $Margin/Layout/Status/StatusLabel
@onready var status_value_label : Label = $Margin/Layout/Status/StatusValue
@onready var session_name_input : LineEdit = $Margin/Layout/Status/SessionName
@onready var sessions_label : Label = $Margin/Layout/SessionsHeader/SessionsLabel
@onready var sessions_container : Control = $Margin/Layout/SessionsContainer
@onready var session_list : Control = $Margin/Layout/SessionsContainer/Sessions
@onready var no_sessions_label : Label = $Margin/Layout/NoSessionsLabel

@onready var start_button : Button = $Margin/Layout/Controls/StartButton
@onready var pause_button : Button = $Margin/Layout/Controls/PauseButton
@onready var resume_button : Button = $Margin/Layout/Controls/ResumeButton
@onready var stop_button : Button = $Margin/Layout/Controls/StopButton
@onready var lap_button : Button = $Margin/Layout/Controls/LapButton

@onready var save_button : Button = $Margin/Layout/SessionsHeader/SaveButton
@onready var restore_button : Button = $Margin/Layout/SessionsHeader/RestoreButton
@onready var clear_button : Button = $Margin/Layout/SessionsHeader/ClearButton

@onready var save_file_dialog : FileDialog = $SaveFileDialog
@onready var restore_file_dialog : FileDialog = $RestoreFileDialog
@onready var clear_confirm_dialog : ConfirmationDialog = $ClearConfirmDialog

func _ready() -> void:
	_update_theme()

	start_button.pressed.connect(_start_tracking)
	pause_button.pressed.connect(_pause_tracking)
	resume_button.pressed.connect(_resume_tracking)
	stop_button.pressed.connect(_stop_tracking)
	lap_button.pressed.connect(_lap_tracking)

	save_button.pressed.connect(_on_save_records_requested)
	restore_button.pressed.connect(_on_restore_records_requested)
	clear_button.pressed.connect(_on_clear_records_requested)

	var default_path = ProjectSettings.globalize_path("res://")
	save_file_dialog.current_dir = default_path
	save_file_dialog.current_path = default_path
	restore_file_dialog.current_dir = default_path
	restore_file_dialog.current_path = default_path

	save_file_dialog.file_selected.connect(_on_save_file_confirmed)
	restore_file_dialog.file_selected.connect(_on_restore_file_confirmed)
	clear_confirm_dialog.confirmed.connect(_on_clear_records_confirmed)

func _process(delta: float) -> void:
	if (!_active_tracking):
		return

	if (_paused_tracking):
		return

	_tracker_elapsed += delta
	status_value_label.text = _format_time(_tracker_elapsed)

# Helpers
func _update_theme() -> void:
	if (!_PluginUtils.get_plugin_instance(self)):
		return

	start_button.icon = get_theme_icon("Play", "EditorIcons")
	pause_button.icon = get_theme_icon("Pause", "EditorIcons")
	resume_button.icon = get_theme_icon("PlayStart", "EditorIcons")
	stop_button.icon = get_theme_icon("Stop", "EditorIcons")
	lap_button.icon = get_theme_icon("Time", "EditorIcons")

	clear_button.icon = get_theme_icon("Remove", "EditorIcons")

	sessions_label.add_theme_color_override("font_color", get_theme_color("contrast_color_2", "Editor"))
	status_label.add_theme_color_override("font_color", get_theme_color("contrast_color_2", "Editor"))
	no_sessions_label.add_theme_color_override("font_color", get_theme_color("contrast_color_2", "Editor"))

func _format_time(sec: float) -> String:
	var time_string = "seconds"
	var pre_string = ""
	var time = int(sec)

	if (time == 1):
		time_string = "second"
	elif (time >= 60):
		time = time / 60
		time_string = "minutes"
		pre_string = "over "

		if (time == 1):
			time_string = "minute"
		elif (time >= 60):
			time = time / 60
			time_string = "hours"

			if (time == 1):
				time_string = "hour"

	return "Working for " + pre_string + str(time) + " " + time_string

func _create_session() -> void:
	var tracker_stopped = Time.get_unix_time_from_system()
	if (_paused_tracking):
		_add_paused_section(tracker_stopped)
	else:
		_add_section(tracker_stopped)

	var session_node = tracker_session.instantiate()
	session_node.session_name = session_name_input.text
	session_node.elapsed_time = tracker_stopped - _tracker_started
	session_node.started_at = _tracker_started
	session_node.stopped_at = tracker_stopped
	session_node.sections = _tracker_sections
	session_list.add_child(session_node)
	session_node.name_changed.connect(_on_session_name_changed)

	session_name_input.text = "Session #" + str(session_list.get_child_count() + 1)

	if (no_sessions_label.visible):
		no_sessions_label.hide()
		sessions_container.show()

func _add_section(tracker_stopped: int) -> void:
	_tracker_sections.append({
		"view": _tracker_main_view,
		"elapsed_time": tracker_stopped - _tracker_main_view_started,
		"started_at": _tracker_main_view_started,
		"stopped_at": tracker_stopped,
	})

func _add_paused_section(paused_stopped: int) -> void:
	_tracker_sections.append({
		"view": "_paused",
		"elapsed_time": paused_stopped - _paused_started,
		"started_at": _paused_started,
		"stopped_at": paused_stopped,
	})

func _mock_session() -> Dictionary:
	if (!_active_tracking):
		return {}

	var tracker_stopped = Time.get_unix_time_from_system()

	var session_data := {
			"session_name": session_name_input.text,
			"elapsed_time": tracker_stopped - _tracker_started,
			"started_at": _tracker_started,
			"stopped_at": tracker_stopped,
			"sections": _tracker_sections.duplicate(true),
	}

	var active_section := {}
	if (_paused_tracking):
		active_section = {
			"view": "_paused",
			"elapsed_time": tracker_stopped - _paused_started,
			"started_at": _paused_started,
			"stopped_at": tracker_stopped,
		}
	else:
		active_section = {
			"view": _tracker_main_view,
			"elapsed_time": tracker_stopped - _tracker_main_view_started,
			"started_at": _tracker_main_view_started,
			"stopped_at": tracker_stopped,
		}

	session_data.sections.append(active_section)

	return session_data

# Tracker functions
func _start_tracking() -> void:
	_tracker_started = Time.get_unix_time_from_system()
	_tracker_main_view_started = _tracker_started
	set_active_tracking(true)

func _pause_tracking() -> void:
	var tracker_stopped = Time.get_unix_time_from_system()
	_add_section(tracker_stopped)
	_tracker_main_view_started = 0
	_paused_started = tracker_stopped
	set_paused_tracking(true)
	status_value_label.text = "Session on hold"

func _resume_tracking() -> void:
	var paused_stopped = Time.get_unix_time_from_system()
	_add_paused_section(paused_stopped)
	set_paused_tracking(false)
	_paused_started = 0
	_tracker_main_view_started = paused_stopped
	status_value_label.text = ""

func _stop_tracking() -> void:
	_create_session()
	set_active_tracking(false)
	_tracker_started = 0
	_tracker_main_view_started = 0
	_tracker_elapsed = 0

	set_paused_tracking(false)
	_paused_started = 0

	_tracker_sections = []
	status_value_label.text = "On a break"
	emit_signal("sessions_changed")

func _lap_tracking() -> void:
	_create_session()
	_tracker_started = Time.get_unix_time_from_system()
	_tracker_main_view_started = _tracker_started
	_tracker_elapsed = 0

	set_paused_tracking(false)
	_paused_started = 0

	_tracker_sections = []
	emit_signal("sessions_changed")

func _clear_records() -> void:
	for child_node in session_list.get_children():
		session_list.remove_child(child_node)
		child_node.queue_free()

	if (!no_sessions_label.visible):
		sessions_container.hide()
		no_sessions_label.show()

# Properties
func set_main_view(view_name: String) -> void:
	if (_tracker_main_view == view_name):
		return

	if (_active_tracking):
		var tracker_stopped = Time.get_unix_time_from_system()
		if (!_paused_tracking):
			_add_section(tracker_stopped)
		_tracker_main_view_started = tracker_stopped

	_tracker_main_view = view_name

func set_active_tracking(value: bool) -> void:
	_active_tracking = value

	if (_active_tracking):
		start_button.disabled = true
		pause_button.disabled = false
		resume_button.disabled = false
		stop_button.disabled = false
		lap_button.disabled = false
	else:
		start_button.disabled = false
		pause_button.disabled = true
		resume_button.disabled = true
		stop_button.disabled = true
		lap_button.disabled = true

func set_paused_tracking(value: bool) -> void:
	_paused_tracking = value

	if (_paused_tracking):
		pause_button.visible = false
		resume_button.visible = true
	else:
		pause_button.visible = true
		resume_button.visible = false

func restore_tracked_sessions(sessions : Array) -> void:
	_clear_records()

	for session_data in sessions:
		var session_node = tracker_session.instantiate()
		session_node.session_name = session_data.session_name
		session_node.elapsed_time = session_data.elapsed_time
		session_node.started_at = session_data.started_at
		session_node.stopped_at = session_data.stopped_at
		session_node.sections = session_data.sections
		session_list.add_child(session_node)
		session_node.name_changed.connect(_on_session_name_changed)

	session_name_input.text = "Session #" + str(session_list.get_child_count() + 1)

	if (no_sessions_label.visible):
		no_sessions_label.hide()
		sessions_container.show()

func get_tracked_sessions() -> Array:
	var sessions := []

	for session_node in session_list.get_children():
		var session_data := {
			"session_name": session_node.session_name,
			"elapsed_time": session_node.elapsed_time,
			"started_at": session_node.started_at,
			"stopped_at": session_node.stopped_at,
			"sections": session_node.sections,
		}

		sessions.append(session_data)

	if (_active_tracking):
		var active_session = _mock_session()
		sessions.append(active_session)

	return sessions

# Event handlers
func _on_save_records_requested() -> void:
	save_file_dialog.popup_centered(save_file_dialog.min_size)

func _on_save_file_confirmed(file_path : String) -> void:
	emit_signal("save_requested", file_path)

func _on_restore_records_requested() -> void:
	restore_file_dialog.popup_centered(restore_file_dialog.min_size)

func _on_restore_file_confirmed(file_path : String) -> void:
	emit_signal("restore_requested", file_path)

func _on_clear_records_requested() -> void:
	clear_confirm_dialog.popup_centered(clear_confirm_dialog.min_size)

func _on_clear_records_confirmed() -> void:
	_clear_records()
	emit_signal("sessions_changed")

func _on_session_name_changed() -> void:
	emit_signal("sessions_changed")
