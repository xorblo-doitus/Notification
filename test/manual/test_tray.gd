extends Control



@onready var notification_tray: NotificationTray = $NotificationTray
@onready var alternative_audio_stream_player: AudioStreamPlayer = $AlternativeAudioStreamPlayer



func _ready() -> void:
	push_random()


func _process(_delta: float) -> void:
	if randi() < 2**25:
		push_random()



func push_random() -> NotificationTray.NotificationHandler:
	return NotificationTray.push_global(
		_get_random_scene().instantiate(),
		NotificationTray.OnGlobalPushFail.WAIT_FOR_SHARED
	)


var _scenes: Array[PackedScene] = [
	preload("res://test/manual/random_notifications/container.tscn"),
	preload("res://test/manual/random_notifications/random_base_notification.tscn"),
	preload("res://test/manual/random_notifications/colored.tscn"),
]
func _get_random_scene() -> PackedScene:
	return _scenes.pick_random()


func _on_add_pressed() -> void:
	push_random()


var _group = NotificationTray.Group.new().set_name("GROUUUP").set_max_amount(3)
func _on_add_group_pressed() -> void:
	var notif: BaseNotification = preload("res://addons/notification/notifications/base_notification.tscn").instantiate()
	notif.set_title("I AM GROUUUUP")
	NotificationTray.push_global(
		notif,
		NotificationTray.OnGlobalPushFail.WAIT_FOR_SHARED
	).set_group(_group).set_audio_stream_player(alternative_audio_stream_player)
