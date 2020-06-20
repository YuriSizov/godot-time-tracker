tool
extends VBoxContainer

# Node references
onready var icon_texture : TextureRect = $Information/IconContainer/Icon
onready var name_label : Label = $Information/NameLabel
onready var elapsed_time_label : Label = $Information/ElapsedLabel

# Public properties
export var section_name : String = "" setget set_section_name
export var section_color : Color = Color.white setget set_section_color
export var elapsed_time : String = "" setget set_elapsed_time

# Private properties
var _section_icon : Texture

func _ready() -> void:
	_update_theme()
	_update_icon()
	_update_name()
	_update_elapsed_time()

# Helpers
func _update_theme() -> void:
	if (!Engine.editor_hint || !is_inside_tree()):
		return
	
	_section_icon = get_icon("Node", "EditorIcons")

func _update_icon() -> void:
	if (!is_inside_tree()):
		return
	
	icon_texture.texture = _section_icon
	icon_texture.modulate = section_color

func _update_name() -> void:
	if (!is_inside_tree()):
		return
	
	name_label.text = section_name

func _update_elapsed_time() -> void:
	if (!is_inside_tree()):
		return
	
	elapsed_time_label.text = elapsed_time

# Properties
func set_section_name(value: String) -> void:
	section_name = value
	_update_name()

func set_section_color(value: Color) -> void:
	section_color = value
	_update_icon()

func set_elapsed_time(value: String) -> void:
	elapsed_time = value
	_update_elapsed_time()
