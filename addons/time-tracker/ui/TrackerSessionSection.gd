@tool
extends VBoxContainer

# Public properties
@export var section_name : String = "":
	set(value):
		section_name = value
		_update_name()

@export var section_color : Color = Color.WHITE:
	set(value):
		section_color = value
		_update_icon()

@export var elapsed_time : String = "":
	set(value):
		elapsed_time = value
		_update_elapsed_time()

# Private properties
var _section_icon : Texture2D

# Utils
const _PluginUtils := preload("../utils/PluginUtils.gd")

# Node references
@onready var icon_texture : TextureRect = $Information/IconContainer/Icon
@onready var name_label : Label = $Information/NameLabel
@onready var elapsed_time_label : Label = $Information/ElapsedLabel

func _ready() -> void:
	_update_theme()
	_update_icon()
	_update_name()
	_update_elapsed_time()

# Helpers
func _update_theme() -> void:
	if (!_PluginUtils.get_plugin_instance(self)):
		return

	_section_icon = get_theme_icon("Node", "EditorIcons")

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
