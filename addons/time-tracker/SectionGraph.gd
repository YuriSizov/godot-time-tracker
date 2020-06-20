tool
extends Control

# Public properties
var section_colors : Dictionary = {}
var sections : Array = [] setget set_sections

# Private properties
var _graph_padding : Vector2 = Vector2(4, 2)
var _background_color : Color = Color.darkgray

func _ready() -> void:
	_update_theme()
	_update_sections()

func _draw() -> void:
	var graph_rect = Rect2(Vector2.ZERO + _graph_padding, rect_size - _graph_padding * 2)
	draw_rect(graph_rect, _background_color, true)
	
	var total_time := 0.0
	var graph_blocks := []
	for section_data in sections:
		var section_name = section_data.view
		var section_color = section_colors["_default"]
		if (section_colors.has(section_name)):
			section_color = section_colors[section_name]
		
		graph_blocks.append({
			"color": section_color,
			"elapsed_time": section_data.elapsed_time,
		})
		total_time += section_data.elapsed_time
	
	var block_offset := _graph_padding.x
	for block_data in graph_blocks:
		var block_size = graph_rect.size.x * (block_data.elapsed_time / total_time)
		
		var block_rect = Rect2(Vector2(block_offset, _graph_padding.y), Vector2(block_size, graph_rect.size.y))
		draw_rect(block_rect, block_data.color, true)
		block_offset += block_size

# Helpers
func _update_theme() -> void:
	if (!Engine.editor_hint || !is_inside_tree()):
		return
	
	_background_color = get_color("contrast_color_1", "Editor")

func _update_sections() -> void:
	if (!is_inside_tree()):
		return
	
	update()

# Properties
func set_sections(value: Array) -> void:
	sections = value
	_update_sections()
