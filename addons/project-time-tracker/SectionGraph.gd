@tool
extends HBoxContainer


# Public properties
var section_colors : Dictionary = {}


var sections : Dictionary = {}:
	set(value):
		sections = value
		_update_sections()


func _update_sections() -> void:
	if (!is_inside_tree()):
		return
	
	var total = 0.0
	for section in sections:
		if (section != "Editor"):
			total += sections[section]
	
	for section in sections:
		if (section == "Editor"):
			continue
		
		if (get_node_or_null(section)):
			get_node(section).size_flags_stretch_ratio = sections[section] / total
		else:
			var new_section = preload("res://addons/project-time-tracker/TrackerSectionColor.tscn").instantiate()
			new_section.name = section
			if section_colors.has(section):
				new_section.color = section_colors[section]
			else:
				new_section.color = section_colors["default"]
			new_section.size_flags_stretch_ratio = floor(sections[section]) / floor(sections["Editor"])
			add_child(new_section)


func clear():
	for child_node in get_children():
		remove_child(child_node)
		child_node.queue_free()
