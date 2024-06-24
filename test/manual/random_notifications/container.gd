extends PanelContainer


signal marked_as_read()


func _init() -> void:
	var stylebox: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = Color(randf(), randf(), randf())
	add_theme_stylebox_override("panel", stylebox)




func _on_button_pressed() -> void:
	marked_as_read.emit()
