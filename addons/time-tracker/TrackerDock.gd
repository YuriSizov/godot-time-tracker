tool
extends Control

# Node references
onready var status_label : Label = $Margin/Layout/Status/StatusLabel
onready var status_value_label : Label = $Margin/Layout/Status/StatusValue
onready var session_name_input : LineEdit = $Margin/Layout/Status/SessionName
onready var sessions_label : Label = $Margin/Layout/SessionsHeader/SessionsLabel
onready var sessions_container : Control = $Margin/Layout/SessionsContainer
onready var session_list : Control = $Margin/Layout/SessionsContainer/Sessions
onready var no_sessions_label : Label = $Margin/Layout/NoSessionsLabel

onready var start_button : Button = $Margin/Layout/Controls/StartButton
onready var pause_button : Button = $Margin/Layout/Controls/PauseButton
onready var resume_button : Button = $Margin/Layout/Controls/ResumeButton
onready var stop_button : Button = $Margin/Layout/Controls/StopButton
onready var lap_button : Button = $Margin/Layout/Controls/LapButton
onready var clear_button : Button = $Margin/Layout/SessionsHeader/ClearButton

# Private properties
var _active_tracking : bool = false
var _tracker_started : int = 0
var _tracker_elapsed : float = 0.0

var _tracker_main_view : String = ""
var _tracker_main_view_started : int = 0
var _tracker_sections : Array = []

var _paused_tracking : bool = false
var _paused_started : int = 0

# Scene references
onready var tracker_session = preload("res://addons/time-tracker/TrackerSession.tscn")

func _ready() -> void:
	_update_theme()
	
	start_button.connect("pressed", self, "_start_tracking")
	pause_button.connect("pressed", self, "_pause_tracking")
	resume_button.connect("pressed", self, "_resume_tracking")
	stop_button.connect("pressed", self, "_stop_tracking")
	lap_button.connect("pressed", self, "_lap_tracking")
	clear_button.connect("pressed", self, "_clear_records")
	
	rect_size = rect_min_size

func _process(delta: float) -> void:
	if (!_active_tracking):
		return
	
	if (_paused_tracking):
		return
	
	_tracker_elapsed += delta
	status_value_label.text = _format_time(_tracker_elapsed)

# Helpers
func _update_theme() -> void:
	if (!Engine.editor_hint || !is_inside_tree()):
		return
	
	start_button.icon = get_icon("Play", "EditorIcons")
	pause_button.icon = get_icon("Pause", "EditorIcons")
	resume_button.icon = get_icon("PlayStart", "EditorIcons")
	stop_button.icon = get_icon("Stop", "EditorIcons")
	lap_button.icon = get_icon("Rotate0", "EditorIcons")
	
	sessions_label.add_color_override("font_color", get_color("contrast_color_2", "Editor"))
	status_label.add_color_override("font_color", get_color("contrast_color_2", "Editor"))
	no_sessions_label.add_color_override("font_color", get_color("contrast_color_2", "Editor"))

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
	var tracker_stopped = OS.get_unix_time()
	if (_paused_tracking):
		_add_paused_section(tracker_stopped)
	else:
		_add_section(tracker_stopped)
	
	var session_node = tracker_session.instance()
	session_node.session_name = session_name_input.text
	session_node.elapsed_time = tracker_stopped - _tracker_started
	session_node.started_at = _tracker_started
	session_node.stopped_at = tracker_stopped
	session_node.sections = _tracker_sections
	session_list.add_child(session_node)
	
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

# Tracker functions
func _start_tracking() -> void:
	_tracker_started = OS.get_unix_time()
	_tracker_main_view_started = _tracker_started
	set_active_tracking(true)

func _pause_tracking() -> void:
	var tracker_stopped = OS.get_unix_time()
	_add_section(tracker_stopped)
	_tracker_main_view_started = 0 
	_paused_started = tracker_stopped
	set_paused_tracking(true)
	status_value_label.text = "Session on hold"

func _resume_tracking() -> void:
	var paused_stopped = OS.get_unix_time()
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

func _lap_tracking() -> void:
	_create_session()
	_tracker_started = OS.get_unix_time()
	_tracker_main_view_started = _tracker_started
	_tracker_elapsed = 0
	
	set_paused_tracking(false)
	_paused_started = 0

	_tracker_sections = []

func _clear_records() -> void:
	for child_node in session_list.get_children():
		session_list.remove_child(child_node)
		child_node.queue_free()

# Properties
func set_main_view(view_name: String) -> void:
	if (_tracker_main_view == view_name):
		return
	
	if (_active_tracking):
		var tracker_stopped = OS.get_unix_time()
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
