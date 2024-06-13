extends ColorRect


func _init() -> void:
	custom_minimum_size = Vector2(randi_range(120, 500), randi_range(50, 75))
	color = Color(randf(), randf(), randf())
