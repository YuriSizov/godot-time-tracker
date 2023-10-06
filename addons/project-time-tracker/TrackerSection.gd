@tool
extends VBoxContainer

signal on_clear_button_pressed(section_name)

# Node references
@onready var icon_texture : TextureRect = $Information/IconContainer/Icon
@onready var name_label : Label = $Information/NameLabel
@onready var elapsed_time_label : Label = $Information/ElapsedLabel
@onready var clear_button : Button = $Information/ClearButton

# Public properties
@export var section_name : String = "" :
	set(value) :
		section_name = value
		_update_name()
	
@export var section_color : Color = Color.WHITE :
	set(value) :
		section_color = value
		_update_icon()
	
@export var elapsed_time : int = 0 :
	set(value) :
		elapsed_time = value
		_update_elapsed_time()

# Private properties
var _section_icon : Texture


func _ready() -> void:

	clear_button.pressed.connect(_on_clear_button_pressed)

	_update_theme()
	_update_icon()
	_update_name()
	_update_elapsed_time()


# Helpers
func _update_theme() -> void:
	if (!Engine.is_editor_hint || !is_inside_tree()):
		return
	
	_section_icon = get_theme_icon("Node", "EditorIcons")
	clear_button.icon = get_theme_icon("Remove", "EditorIcons")


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
	
	elapsed_time_label.text = Time.get_time_string_from_unix_time(elapsed_time)


func _on_clear_button_pressed():
	on_clear_button_pressed.emit(section_name)
