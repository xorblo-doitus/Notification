class_name NotificationTray
extends VBoxContainer


## An in-game notification tray to display things such as achievments, errors...


enum AppearAnimation {
	COME_FROM_LEFT,
	COME_FROM_RIGHT,
	COME_FROM_UP,
	COME_FROM_DOWN,
	TRANSPARENCY,
	## Use [member custom_appear_animation].
	CUSTOM,
}

enum DisappearAnimation {
	GO_TO_LEFT,
	GO_TO_RIGHT,
	GO_TO_UP,
	GO_TO_DOWN,
	TRANSPARENCY,
	## Use [member custom_disappear_animation].
	CUSTOM,
}

enum Gravity {
	## Notifications appear at the top and fall down when the lower one disappear.
	NORMAL,
	## Notifications appear at the bottom and fly up when the upper one disappear.
	UPSIDE_DOWN,
}

## The maximum amount of notification that can be visible at a time.
@export var maximum_shown_notifications: int = 50:
	set(new):
		maximum_shown_notifications = new
		while _queued_handlers and _shown_handlers.size() < maximum_shown_notifications:
			_process_handler.call_deferred(_queued_handlers.pop_front())
@export var notification_duration: float = 3.0
@export var notification_duration_multiplier: float = 1.0
@export var notification_squish_time: float = 0.5
@export var notifications_size_flags_horizontal: SizeFlags = SIZE_SHRINK_END

@export var gravity: Gravity = Gravity.NORMAL:
	set(new):
		gravity = new
		alignment = (
			BoxContainer.ALIGNMENT_END
			if gravity == Gravity.NORMAL
			else BoxContainer.ALIGNMENT_BEGIN
		)

@export_group("Appear animation", "appear_animation")
@export var appear_animation_type: AppearAnimation = AppearAnimation.COME_FROM_RIGHT
@export var appear_animation_time: float = 0.2
@export var appear_animation_trans: Tween.TransitionType = Tween.TRANS_QUAD
@export var appear_animation_ease: Tween.EaseType = Tween.EASE_OUT
## When [member gravity] is upside down and [member appear_animation_type]
## is come from up, forces incoming
## notification to have a -1 relative z_index, so that they don't hide
## already here notifications while traveling.
@export var incoming_behind: bool = true
@export_group("Disappear animation", "disappear_animation")
@export var disappear_animation_type: DisappearAnimation = DisappearAnimation.GO_TO_DOWN
@export var disappear_animation_time: float = 0.2
@export var disappear_animation_trans: Tween.TransitionType = Tween.TRANS_QUAD
@export var disappear_animation_ease: Tween.EaseType = Tween.EASE_OUT
## When [member gravity] is normal and [member disappear_animation_type]
## is go to up, forces outgoing
## notification to have a -1 relative z_index, so that they don't hide
## already here notifications while traveling.
@export var outgoing_behind: bool = true
@export_group("")


## A callable making a notification appear. Will only be used if
## [member appear_animation_type] is set to
## [enum NotificationTray.AppearAnimation][code].CUSTOM[/code].
## It can be an awaitable coroutine.
## [codeblock]
## func foo_animation(notif: Control) -> void:
##     notif.show()
## [/codeblock]
var custom_appear_animation: Callable
## A callable making a notification disappear. Will only be used if
## [member disappear_animation_type] is set to
## [enum NotificationTray.DisappearAnimation][code].CUSTOM[/code].
## It [b]must[/b] be an awaitable coroutine so that the notification don't
## disappear intantly.
## [codeblock]
## func foo_animation(notif: Control) -> void:
##     await notif.get_tree().create_timer(1).timeout
##     notif.hide()
## [/codeblock]
var custom_disappear_animation: Callable


var _queued_handlers: Array[NotificationHandler] = []
var _shown_handlers: Array[NotificationHandler] = []
var _group_cache: Array = []
func push(notif: Control) -> NotificationHandler:
	var handler: NotificationHandler = NotificationHandler.new()
	handler._notif = notif
	handler.appear_animator = _appear_animator
	handler.disappear_animator = _disappear_animator
	handler.duration = notification_duration
	handler.duration_multiplier = notification_duration_multiplier
	
	notif.size_flags_horizontal = notifications_size_flags_horizontal
	
	_process_handler.call_deferred(handler)
	
	return handler


func _process_handler(handler: NotificationHandler) -> void:
	if handler.group != null and handler.group in _group_cache:
		return
	
	if _shown_handlers.size() >= maximum_shown_notifications:
		_queued_handlers.append(handler)
		return
	
	_push_handler(handler)
	
	
	handler._notif.hide()
	add_child(handler._notif)
	if gravity == Gravity.NORMAL:
		move_child(handler._notif, 0)
	
	await handler.appear()
	
	await get_tree().create_timer(
		handler.duration * handler.duration_multiplier,
	).timeout
	
	await handler.disappear()
	
	await handler.squish(notification_squish_time)
	
	handler._notif.free()
	_shown_handlers.erase(handler)
	
	if _queued_handlers:
		_process_handler.call_deferred(_queued_handlers.pop_front())
	else:
		_rebuild_group_cache()


func _push_handler(new_handler: NotificationHandler) -> void:
	_shown_handlers.push_back(new_handler)
	_rebuild_group_cache()


func _rebuild_group_cache() -> void:
	_group_cache.clear()
	
	for handler in _shown_handlers:
		if handler.group !=  null and handler.group not in _group_cache:
			_group_cache.push_back(handler.group)


func _appear_animator(notif: Control) -> void:
	match appear_animation_type:
		AppearAnimation.CUSTOM:
			custom_appear_animation.call(notif)
		AppearAnimation.TRANSPARENCY:
			notif.modulate.a = 0
			notif.show()
			await _apply_appear_tween_properties(notif.create_tween().tween_property(
				notif,
				^"modulate:a",
				1,
				appear_animation_time,
			)).finished
		AppearAnimation.COME_FROM_LEFT, AppearAnimation.COME_FROM_RIGHT, AppearAnimation.COME_FROM_UP, AppearAnimation.COME_FROM_DOWN:
			if _shall_apply_incomming_behind():
				notif.z_index = -1
			
			notif.show()
			var container: Control = _build_container_for(notif)
			notif.position = _get_offset_to_offscreen(appear_animation_type, notif)
			
			await _apply_appear_tween_properties(notif.create_tween().tween_property(
				notif,
				^"position",
				Vector2(0, 0),
				appear_animation_time,
			).from(_get_offset_to_offscreen(appear_animation_type, notif))).finished
			
			_remove_container(container, notif)
			
			if _shall_apply_incomming_behind():
				notif.z_index = 0


func _apply_appear_tween_properties(property_tweener: PropertyTweener) -> PropertyTweener:
	return property_tweener.set_trans(
		appear_animation_trans,
	).set_ease(
		appear_animation_ease,
	)


func _disappear_animator(notif: Control) -> void:
	match disappear_animation_type:
		DisappearAnimation.CUSTOM:
			custom_disappear_animation.call(notif)
		DisappearAnimation.TRANSPARENCY:
			await _apply_disappear_tween_properties(notif.create_tween().tween_property(
				notif,
				^"modulate:a",
				0,
				appear_animation_time,
			)).finished
		DisappearAnimation.GO_TO_LEFT, DisappearAnimation.GO_TO_RIGHT, DisappearAnimation.GO_TO_UP, DisappearAnimation.GO_TO_DOWN:
			if _shall_apply_outgoing_behind():
				notif.z_index = -1
			
			var container: CenterContainer = _build_container_for(notif)
			notif.show()
			
			await _apply_disappear_tween_properties(notif.create_tween().tween_property(
				notif,
				^"position",
				_get_offset_to_offscreen(disappear_animation_type, notif),
				disappear_animation_time,
			).from(Vector2(0, 0))).finished
			
			_remove_container(container, notif)
			
			if _shall_apply_outgoing_behind():
				notif.z_index = 0


func _apply_disappear_tween_properties(property_tweener: PropertyTweener) -> PropertyTweener:
	return property_tweener.set_trans(
		disappear_animation_trans,
	).set_ease(
		disappear_animation_ease,
	)


func _shall_apply_incomming_behind() -> bool:
	return (
		incoming_behind
		and appear_animation_type == AppearAnimation.COME_FROM_UP
		and gravity == Gravity.UPSIDE_DOWN
	)


func _shall_apply_outgoing_behind() -> bool:
	return (
		outgoing_behind
		and disappear_animation_type == DisappearAnimation.GO_TO_UP
		and gravity == Gravity.NORMAL
	)


func _get_offset_to_offscreen(animation: int, notif: Control) -> Vector2:
	match animation:
		AppearAnimation.COME_FROM_LEFT:
			return Vector2(-notif.get_viewport_rect().size.x, 0)
		AppearAnimation.COME_FROM_RIGHT:
			return Vector2(notif.get_viewport_rect().size.x, 0)
		AppearAnimation.COME_FROM_UP:
			return Vector2(0, -notif.get_viewport_rect().size.x)
		AppearAnimation.COME_FROM_DOWN:
			return Vector2(0, notif.get_viewport_rect().size.x)
	assert(false, "Unkown animation" + str(animation))
	return Vector2(0, 0)


func _build_container_for(notif: Control) -> Control:
	var container: Control = Control.new()
	container.custom_minimum_size = notif.size
	container.size_flags_horizontal = notif.size_flags_horizontal
	notif.add_sibling(container)
	notif.reparent(container, false)
	return container


func _remove_container(container: Control, notif: Control) -> void:
	container.remove_child(notif)
	container.add_sibling(notif)
	remove_child(container)
	container.queue_free()


class NotificationHandler extends RefCounted:
	var appear_animator: Callable
	func set_appear_animator(animator: Callable) -> NotificationHandler:
		appear_animator = animator
		return self
	
	var disappear_animator: Callable
	func set_disappear_animator(animator: Callable) -> NotificationHandler:
		disappear_animator = animator
		return self
	
	## If there is already a notification of the same group (and if group is
	## not null), this notification will be discarded.
	var group: Variant
	func set_group(new_group: Variant) -> NotificationHandler:
		group = new_group
		return self
	
	var duration: float
	func set_duration(new_duration: float) -> NotificationHandler:
		duration = new_duration
		return self
	
	var duration_multiplier: float
	func set_duration_multiplier(new_duration_multiplier: float) -> NotificationHandler:
		duration_multiplier = new_duration_multiplier
		return self
	
	var _notif: Control
	
	
	func appear() -> void:
		await appear_animator.call(_notif)
	
	func disappear() -> void:
		await disappear_animator.call(_notif)
	
	func squish(duration: float) -> void:
		var dummy: Control = Control.new()
		_notif.add_sibling(dummy)
		dummy.custom_minimum_size = _notif.size
		_notif.get_parent().remove_child(_notif)
		
		await dummy.create_tween().tween_property(
			dummy,
			^"custom_minimum_size:y",
			0,
			duration,
		).finished
		
		dummy.queue_free()
