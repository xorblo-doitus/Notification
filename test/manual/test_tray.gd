extends Control



@onready var notification_tray: NotificationTray = $NotificationTray



func _ready() -> void:
	push_random()


func _process(_delta: float) -> void:
	if randi() < 2**25:
		push_random()



func push_random() -> void:
	NotificationTray.push_global(_get_random_scene().instantiate())


var _scenes: Array[PackedScene] = [
	preload("res://test/manual/random_notifications/container.tscn"),
	preload("res://test/manual/random_notifications/random_base_notification.tscn"),
	preload("res://test/manual/random_notifications/colored.tscn"),
]
func _get_random_scene() -> PackedScene:
	return _scenes.pick_random()


func _on_add_pressed() -> void:
	push_random()
