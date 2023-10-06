@tool
extends ColorRect


func _process(delta: float) -> void:
	if (!Engine.is_editor_hint || !is_inside_tree()):
		return
		
	var percent = floor(size_flags_stretch_ratio * 100)
		
	if (percent >= 10):
		$Percent.text = str(percent) + "%"
	else:
		$Percent.text = ""
