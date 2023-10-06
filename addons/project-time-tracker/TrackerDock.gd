@tool
extends Control


# Node references
@onready var status_label : Label = $Margin/Layout/Status/StatusLabel
@onready var status_value_label : Label = $Margin/Layout/Status/StatusValue
@onready var pause_button : Button = $Margin/Layout/Controls/PauseButton
@onready var resume_button : Button = $Margin/Layout/Controls/ResumeButton
@onready var clear_button : Button = $Margin/Layout/Status/ClearButton
@onready var section_list : Control = $Margin/Layout/SectionList
@onready var section_graph : Control = $Margin/Layout/SectionGraph
@onready var clear_confirm_dialog : ConfirmationDialog = $ClearConfirmDialog
@onready var clear_section_confirm_dialog : ConfirmationDialog = $ClearSectionConfirmDialog
@onready var timer_update : Timer = $TimerUpdate


# Private properties
var _active_tracking : bool = false
var _tracker_started : float = 0.0
var _tracker_main_view : String = ""
var _tracker_sections : Dictionary = {}
var _section_to_remove : String = ""

var _section_colors : Dictionary = {
	"2D": Color.DEEP_SKY_BLUE,
	"3D": Color.CORAL,
	"Script": Color.YELLOW,
	"AssetLib": Color.MEDIUM_SEA_GREEN,
	"default": Color.WHITE
}


# Scene references
@onready var section_scene = preload("res://addons/project-time-tracker/TrackerSection.tscn")


func _ready() -> void:
	_update_theme()
	
	section_graph.section_colors = _section_colors
	
	pause_button.pressed.connect(_pause_tracking)
	resume_button.pressed.connect(_resume_tracking)
	clear_button.pressed.connect(_on_clear_records_requested)
	clear_confirm_dialog.confirmed.connect(_on_clear_records_confirmed)
	clear_section_confirm_dialog.confirmed.connect(_on_clear_section_confirmed)
	timer_update.timeout.connect(_on_timer_update_timeout)
	
	_tracker_started = Time.get_unix_time_from_system()
	
	_set_active_tracking(true)
	
	timer_update.start()


func _process(delta: float) -> void:
	if (!_active_tracking):
		return
	
	var time_elapsed = 0.0
	for section in _tracker_sections:
		if section != "Editor":
			time_elapsed += _tracker_sections[section]
	
	_tracker_sections["Editor"] = time_elapsed
	status_value_label.text = "Working for " + Time.get_time_string_from_unix_time(_tracker_sections["Editor"])


# Helpers
func _update_theme() -> void:
	if (!Engine.is_editor_hint || !is_inside_tree()):
		return
	
	pause_button.icon = get_theme_icon("Pause", "EditorIcons")
	resume_button.icon = get_theme_icon("PlayStart", "EditorIcons")
	clear_button.icon = get_theme_icon("Remove", "EditorIcons")
	status_label.add_theme_color_override("font_color", get_theme_color("contrast_color_2", "Editor"))


func _create_section(section_name: String) -> bool:
	if (!Engine.is_editor_hint || !is_inside_tree()):
		return false
	
	if (section_name.is_empty()):
		return false
	
	if section_list.get_node_or_null(section_name):
		return true
	
	var new_section = section_scene.instantiate()
	new_section.name = section_name
	new_section.section_name = section_name
	new_section.on_clear_button_pressed.connect(_on_clear_section_requested)
	if _section_colors.has(section_name):
		new_section.section_color = _section_colors[section_name]
	else:
		new_section.section_color = _section_colors["default"]
	section_list.add_child(new_section)
	
	_tracker_sections[section_name] = 0
		
	return true


func _update_sections() -> void:
	if (!Engine.is_editor_hint || !is_inside_tree()):
		return

	for section in _tracker_sections:
		var node = section_list.get_node_or_null(section)
		if (node):
			node.elapsed_time = _tracker_sections[section]
	
	section_graph.sections = _tracker_sections


# Tracker functions
func _resume_tracking() -> void:
	_set_active_tracking(true)
	_tracker_started = Time.get_unix_time_from_system()


func _pause_tracking() -> void:
	_set_active_tracking(false)
	if (_create_section(_tracker_main_view)):
		var elapsed_time = Time.get_unix_time_from_system() - _tracker_started
		_tracker_sections[_tracker_main_view] += elapsed_time
	status_value_label.text = "Pause (" + Time.get_time_string_from_unix_time(_tracker_sections["Editor"]) + ")"


# Properties
func set_main_view(view_name: String) -> void:
	if (_tracker_main_view == view_name):
		return
		
	#Save only for an minimum elasped time
	var elapsed_time = Time.get_unix_time_from_system() - _tracker_started

	if (_active_tracking and elapsed_time >= 1 and _create_section(_tracker_main_view)):
		_tracker_sections[_tracker_main_view] += elapsed_time
		_tracker_started = Time.get_unix_time_from_system()
	
	_tracker_main_view = view_name


func _set_active_tracking(value: bool) -> void:
	_active_tracking = value
	
	if (_active_tracking):
		pause_button.disabled = false
		resume_button.disabled = true
	else:
		pause_button.disabled = true
		resume_button.disabled = false


func restore_tracked_sections(sections : Dictionary) -> void:
	for section in sections:
		if (section != "Editor"):
			_create_section(section)
		_tracker_sections[section] = sections[section]
	_update_sections()


func get_tracked_sections() -> Dictionary:
	return _tracker_sections


# Event handlers
func _on_clear_records_requested() -> void:
	clear_confirm_dialog.popup_centered(clear_confirm_dialog.size)


func _on_clear_records_confirmed() -> void:
	_tracker_sections.clear()
	for child_node in section_list.get_children():
		section_list.remove_child(child_node)
		child_node.queue_free()
	section_graph.clear()


func _on_timer_update_timeout():
	if (_active_tracking and _create_section(_tracker_main_view)):
		var elapsed_time = Time.get_unix_time_from_system() - _tracker_started
		_tracker_sections[_tracker_main_view] += elapsed_time
		_tracker_started = Time.get_unix_time_from_system()
		_update_sections()


func _on_clear_section_requested(section_name):
	_section_to_remove = section_name
	clear_section_confirm_dialog.dialog_text = "This action will remove " + section_name + " section from memory.\n\nDo you want to continue?"
	clear_section_confirm_dialog.popup_centered(clear_section_confirm_dialog.size)


func _on_clear_section_confirmed():
	_tracker_sections.erase(_section_to_remove)
	
	if (_tracker_main_view == _section_to_remove):
		_tracker_started = Time.get_unix_time_from_system()

	var child_node = section_list.get_node(_section_to_remove)
	section_list.remove_child(child_node)
	child_node.queue_free()
	
	_section_to_remove = ""
	section_graph.clear()
	_update_sections()
