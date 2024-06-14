extends Control



@onready var notification_tray: NotificationTray = $NotificationTray



func _ready() -> void:
	push_random()


func _process(_delta: float) -> void:
	if randi() < 2**25:
		push_random()



func push_random() -> void:
	notification_tray.push(_get_random_scene().instantiate())


func _get_random_scene() -> PackedScene:
	if randf() < 0.5:
		return preload("res://test/manual/random_notifications/container.tscn")
	
	return preload("res://test/manual/random_notifications/colored.tscn")


func _on_add_pressed() -> void:
	push_random()
