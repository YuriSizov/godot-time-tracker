tool
extends PanelContainer

# Node references
onready var status_label : Label = $Layout/Status/StatusLabel
onready var status_value_label : Label = $Layout/Status/StatusValue
onready var session_name_input : LineEdit = $Layout/Status/SessionName
onready var sessions_label : Label = $Layout/SessionsHeader/SessionsLabel
onready var sessions_container : Control = $Layout/SessionsContainer
onready var session_list : Control = $Layout/SessionsContainer/Sessions
onready var no_sessions_label : Label = $Layout/NoSessionsLabel

onready var start_button : Button = $Layout/Controls/StartButton
onready var stop_button : Button = $Layout/Controls/StopButton
onready var lap_button : Button = $Layout/Controls/LapButton
onready var clear_button : Button = $Layout/SessionsHeader/ClearButton

# Private properties
var _active_tracking : bool = false
var _tracker_started : int = 0
var _tracker_main_view : String = ""
var _tracker_main_view_started : int = 0
var _tracker_sections : Array = []

# Scene references
onready var tracker_session = preload("res://addons/time-tracker/TrackerSession.tscn")

func _ready() -> void:
	_update_theme()
	
	start_button.connect("pressed", self, "_start_tracking")
	stop_button.connect("pressed", self, "_stop_tracking")
	lap_button.connect("pressed", self, "_lap_tracking")
	clear_button.connect("pressed", self, "_clear_records")
	
	rect_size = rect_min_size

func _process(delta: float) -> void:
	if (!_active_tracking):
		return
	
	status_value_label.text = _format_time(OS.get_ticks_msec() - _tracker_started)

# Helpers
func _update_theme() -> void:
	if (!Engine.editor_hint || !is_inside_tree()):
		return
	
	start_button.icon = get_icon("Play", "EditorIcons")
	stop_button.icon = get_icon("Stop", "EditorIcons")
	lap_button.icon = get_icon("Rotate0", "EditorIcons")
	
	sessions_label.add_color_override("font_color", get_color("contrast_color_2", "Editor"))
	status_label.add_color_override("font_color", get_color("contrast_color_2", "Editor"))
	no_sessions_label.add_color_override("font_color", get_color("contrast_color_2", "Editor"))

func _format_time(msec: int) -> String:
	var time_string = "seconds"
	var pre_string = ""
	var time = msec / 1000
	
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
	var tracker_stopped = OS.get_ticks_msec()
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

func _add_section(tracker_stopped) -> void:
	_tracker_sections.append({
		"view": _tracker_main_view,
		"elapsed_time": tracker_stopped - _tracker_main_view_started,
		"started_at": _tracker_main_view_started,
		"stopped_at": tracker_stopped,
	})

# Tracker functions
func _start_tracking() -> void:
	_tracker_started = OS.get_ticks_msec()
	_tracker_main_view_started = _tracker_started
	set_active_tracking(true)

func _stop_tracking() -> void:
	_create_session()
	set_active_tracking(false)
	_tracker_started = 0
	_tracker_main_view_started = 0
	_tracker_sections = []
	status_value_label.text = "On a break"

func _lap_tracking() -> void:
	_create_session()
	_tracker_started = OS.get_ticks_msec()
	_tracker_main_view_started = _tracker_started
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
		var tracker_stopped = OS.get_ticks_msec()
		_add_section(tracker_stopped)
		_tracker_main_view_started = tracker_stopped
	
	_tracker_main_view = view_name

func set_active_tracking(value: bool) -> void:
	_active_tracking = value
	
	if (_active_tracking):
		start_button.disabled = true
		stop_button.disabled = false
		lap_button.disabled = false
	else:
		start_button.disabled = false
		stop_button.disabled = true
		lap_button.disabled = true
