extends PanelContainer


func _init() -> void:
	var stylebox: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = Color(randf(), randf(), randf())
	add_theme_stylebox_override("panel", stylebox)
