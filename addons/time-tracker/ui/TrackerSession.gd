@tool
extends VBoxContainer

signal name_changed()

# Public properties
@export var session_name : String = "":
	set(value):
		session_name = value
		_update_name()

@export var elapsed_time : int = 0:
	set(value):
		elapsed_time = value
		_update_elapsed_time()

@export var started_at : int = 0:
	set(value):
		started_at = value
		_update_started_time()

@export var stopped_at : int = 0:
	set(value):
		stopped_at = value
		_update_stopped_time()

@export var sections : Array = []:
	set(value):
		sections = value
		_update_sections()

# Private properties
var _section_colors : Dictionary = {
	"_default": Color.WHITE,
	"_paused": Color.DARK_GRAY,
	"2D": Color.AQUA,
	"3D": Color.ROSY_BROWN,
	"Script": Color.YELLOW,
	"AssetLib": Color.CORAL,
}

# Utils
const _PluginUtils := preload("../utils/PluginUtils.gd")

# Scene references
@onready var section_scene = preload("./TrackerSessionSection.tscn")

# Node references
@onready var name_label : Label = $Information/NameLabel
@onready var name_input : LineEdit = $Information/NameEdit
@onready var edit_name_button : Button = $Information/EditNameButton
@onready var save_name_button : Button = $Information/SaveNameButton
@onready var cancel_name_button : Button = $Information/CancelNameButton
@onready var elapsed_time_label : Label = $Information/ElapsedLabel
@onready var expand_sections_button : Button = $Information/ExpandSectionsButton

@onready var sections_container : Control = $Sections
@onready var section_list : Control = $Sections/Layout/SectionList
@onready var section_graph : Control = $Sections/Layout/SectionGraph
@onready var started_time : Control = $Sections/Layout/StartedTime
@onready var started_time_label : Label = $Sections/Layout/StartedTime/StartedTimeLabel
@onready var started_time_value : Label = $Sections/Layout/StartedTime/StartedTimeValue
@onready var stopped_time : Control = $Sections/Layout/StoppedTime
@onready var stopped_time_label : Label = $Sections/Layout/StoppedTime/StoppedTimeLabel
@onready var stopped_time_value : Label = $Sections/Layout/StoppedTime/StoppedTimeValue

func _ready() -> void:
	_update_theme()
	_update_name()
	_update_elapsed_time()
	_update_started_time()
	_update_stopped_time()
	_update_sections()

	section_graph.section_colors = _section_colors

	edit_name_button.pressed.connect(_on_edit_name_pressed)
	save_name_button.pressed.connect(_on_save_name_pressed)
	cancel_name_button.pressed.connect(_on_cancel_name_pressed)
	name_input.gui_input.connect(_on_name_input_event)

	expand_sections_button.pressed.connect(_on_expand_sections_pressed)

# Helpers
func _format_time(elapsed_seconds: int) -> String:
	var time_string = ""

	if (elapsed_seconds == 0):
		time_string = "less than a second"
	else:
		var time_seconds = elapsed_seconds % 60
		var time_minutes = (elapsed_seconds / 60) % 60
		var time_hours = (elapsed_seconds / 60) / 60

		if (time_hours > 0):
			time_string += str(time_hours) + " hr "
		if (time_minutes > 0):
			time_string += str(time_minutes) + " min "
		if (time_seconds > 0):
			time_string += str(time_seconds) + " sec "

	return time_string

func _format_datetime(unix_time: int) -> String:
	var timezone = Time.get_time_zone_from_system()
	var datetime = Time.get_datetime_dict_from_unix_time(unix_time + timezone["bias"] * 60)

	return str(datetime["hour"]) + ":" + str(datetime["minute"]).pad_zeros(2)

func _format_datetime_iso(unix_time: int) -> String:
	var datetime = Time.get_datetime_dict_from_unix_time(unix_time)

	var result = ""
	result += str(datetime["year"]) + "-" + str(datetime["month"]).pad_zeros(2) + "-" + str(datetime["day"]).pad_zeros(2)
	result += "T" + str(datetime["hour"]).pad_zeros(2) + ":" + str(datetime["minute"]).pad_zeros(2) + ":" + str(datetime["second"]).pad_zeros(2) + "Z"

	return result

func _update_theme() -> void:
	if (!_PluginUtils.get_plugin_instance(self)):
		return

	edit_name_button.icon = get_theme_icon("Edit", "EditorIcons")
	save_name_button.icon = get_theme_icon("ImportCheck", "EditorIcons")
	cancel_name_button.icon = get_theme_icon("ImportFail", "EditorIcons")
	expand_sections_button.icon = get_theme_icon("Collapse", "EditorIcons")

	var panel_style = get_theme_stylebox("panel", "Panel").duplicate(true)
	if (panel_style is StyleBoxFlat):
		panel_style.bg_color = get_theme_color("dark_color_1", "Editor")
	sections_container.add_theme_stylebox_override("panel", panel_style)

	started_time_label.add_theme_color_override("font_color", get_theme_color("contrast_color_2", "Editor"))
	stopped_time_label.add_theme_color_override("font_color", get_theme_color("contrast_color_2", "Editor"))

	_section_colors["_paused"] = get_theme_color("contrast_color_1", "Editor")
	_section_colors["2D"] = get_theme_color("axis_z_color", "Editor")
	_section_colors["3D"] = get_theme_color("error_color", "Editor")
	_section_colors["Script"] = get_theme_color("warning_color", "Editor")
	_section_colors["AssetLib"] = get_theme_color("success_color", "Editor")

func _update_name() -> void:
	if (!is_inside_tree()):
		return

	name_label.text = session_name
	name_input.text = session_name

func _update_elapsed_time() -> void:
	if (!is_inside_tree()):
		return

	elapsed_time_label.text = _format_time(elapsed_time)

func _update_started_time() -> void:
	if (!is_inside_tree()):
		return

	started_time_value.text = _format_datetime(started_at)
	started_time.tooltip_text = _format_datetime_iso(started_at)

func _update_stopped_time() -> void:
	if (!is_inside_tree()):
		return

	stopped_time_value.text = _format_datetime(stopped_at)
	stopped_time.tooltip_text = _format_datetime_iso(stopped_at)

func _update_sections() -> void:
	if (!is_inside_tree()):
		return

	for child_node in section_list.get_children():
		section_list.remove_child(child_node)
		child_node.queue_free()

	if (sections.size() == 0):
		sections_container.hide()
		expand_sections_button.hide()
		return

	var grouped_sections := {}
	for section_data in sections:
		var section_name = section_data.view
		if (!grouped_sections.has(section_name)):
			grouped_sections[section_name] = {
				"elapsed_time": 0,
			}

		grouped_sections[section_name].elapsed_time += section_data.elapsed_time

	for section_name in grouped_sections:
		var section_data = grouped_sections[section_name]

		var section_color = _section_colors["_default"]
		if (_section_colors.has(section_name)):
			section_color = _section_colors[section_name]

		var section_node = section_scene.instantiate()
		section_node.section_name = section_name
		if (section_name == "_paused"):
			section_node.section_name = "> Intermission"

		section_node.section_color = section_color
		section_node.elapsed_time = _format_time(section_data.elapsed_time)
		section_list.add_child(section_node)

	section_graph.sections = sections

	expand_sections_button.show()

# Event handlers
func _on_edit_name_pressed() -> void:
	name_label.hide()
	edit_name_button.hide()
	name_input.show()
	save_name_button.show()
	cancel_name_button.show()

func _on_save_name_pressed() -> void:
	name_input.hide()
	save_name_button.hide()
	cancel_name_button.hide()

	session_name = name_input.text
	name_label.text = session_name

	name_label.show()
	edit_name_button.show()
	emit_signal("name_changed")

func _on_cancel_name_pressed() -> void:
	name_input.hide()
	save_name_button.hide()
	cancel_name_button.hide()

	name_input.text = session_name

	name_label.show()
	edit_name_button.show()

func _on_name_input_event(event: InputEvent) -> void:
	if (event is InputEventKey && event.pressed && !event.echo):
		if (event.keycode == KEY_ENTER || event.keycode == KEY_KP_ENTER):
			_on_save_name_pressed()

func _on_expand_sections_pressed() -> void:
	sections_container.visible = !sections_container.visible
