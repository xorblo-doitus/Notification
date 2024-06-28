class_name NotificationTray
extends VBoxContainer


## An in-game notification tray to display things such as achievments, errors...
##
## [b]Note:[/b] If the pushed notification has a [code]marked_as_read[/code]
## signal, the notification will be closed early when this signal is emitted.
##
## [b]Note:[/b] If the pushed notification has a [code]group_marked_as_read[/code]
## signal, all notifications of the same group will be closed early
## when this signal is emitted.
##
## [b]Note:[/b] If the pushed notification has a [code]group_ignored[/code]
## signal, [method ignore_group] will be called
## when this signal is emitted.


## Emitted when a notification was ignored, for example because a notification
## of the same group was already shown.
signal notification_droped(handler: NotificationHandler)
## Emitted when a notif is [i]pushed[/i]. It does not always mean that it appeared.
signal notification_pushed(handler: NotificationHandler)
signal notification_appearing(handler: NotificationHandler)
signal notification_appeared(handler: NotificationHandler)
signal notification_disappearing(handler: NotificationHandler)
signal notification_disappeared(handler: NotificationHandler)
## Emitted when the notif disappeared and was squished to smoothly release room.
signal notification_squished(handler: NotificationHandler)


enum AppearAnimation {
	NONE,
	COME_FROM_LEFT,
	COME_FROM_RIGHT,
	COME_FROM_UP,
	COME_FROM_DOWN,
	TRANSPARENCY,
	## Use [member custom_appear_animation].
	CUSTOM,
}

enum DisappearAnimation {
	NONE,
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


## An optional singleton for project-wise notifications.
## See [member use_as_singleton] and [method push_global].
static var shared: NotificationTray:
	set(new):
		shared = new
		_process_on_hold_notifications()


## If true, this tray will be accessible trough [member NotificationTray.shared].
@export var use_as_singleton: bool = true:
	set(new):
		use_as_singleton = new
		if use_as_singleton:
			NotificationTray.shared = self
		elif NotificationTray.shared == self:
			NotificationTray.shared = null
## The maximum amount of notification that can be visible at a time.
@export var maximum_shown_notifications: int = 50:
	set(new):
		maximum_shown_notifications = new
		while _queued_handlers and _shown_handlers.size() < maximum_shown_notifications:
			_process_handler.call_deferred(_queued_handlers.pop_front())
## Played every time a notifiation appear.
@export var audio_stream_player: AudioStreamPlayer

@export var gravity: Gravity = Gravity.NORMAL:
	set(new):
		gravity = new
		alignment = (
			BoxContainer.ALIGNMENT_END
			if gravity == Gravity.NORMAL
			else BoxContainer.ALIGNMENT_BEGIN
		)

@export_group("Notifications", "notifications_")
@export var notifications_duration: float = 3.0
@export var notifications_duration_multiplier: float = 1.0
@export var notifications_squish_time: float = 0.5
@export var notifications_size_flags_horizontal: SizeFlags = SIZE_SHRINK_END

@export_group("Appear animation", "appear_animation")
@export var appear_animation_type: AppearAnimation = AppearAnimation.COME_FROM_RIGHT
@export var appear_animation_time: float = 0.2
@export var appear_animation_trans: Tween.TransitionType = Tween.TRANS_QUAD
@export var appear_animation_ease: Tween.EaseType = Tween.EASE_OUT
## When [member gravity] is upside down and [member appear_animation_type]
## is come from up, forces incoming
## notification to have a -1 relative z_index, so that they don't hide
## already here notifications while traveling.
@export var appear_animation_behind: bool = true

@export_group("Disappear animation", "disappear_animation")
@export var disappear_animation_type: DisappearAnimation = DisappearAnimation.GO_TO_DOWN
@export var disappear_animation_time: float = 0.2
@export var disappear_animation_trans: Tween.TransitionType = Tween.TRANS_QUAD
@export var disappear_animation_ease: Tween.EaseType = Tween.EASE_OUT
## When [member gravity] is normal and [member disappear_animation_type]
## is go to up, forces outgoing
## notification to have a -1 relative z_index, so that they don't hide
## already here notifications while traveling.
@export var disappear_animation_behind: bool = true
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
## Notification whose group is in this array is automatically marked as read.
var ignored_groups: Array[Group] = []


enum OnGlobalPushFail {
	## Do nothing
	NONE,
	## Call [method Node.queue_free] on the notif.
	QUEUE_FREE,
	## Call [method Object.free] on the notif.
	FREE,
	## Place this notif on hold until [member shared] is defined.
	WAIT_FOR_SHARED,
}
static var _global_notifications_on_hold: Array[NotificationHandler] = []
## If [member NotificationTray.shared] is defined (or if [param failure_behavior]
## is WAIT_FOR_SHARED), push notification to it
## and return the handler, otherwise return null.
## In failure case, reacts accordingly to [param failure_behavior].
static func push_global(notif: Control, failure_behavior: OnGlobalPushFail = OnGlobalPushFail.NONE) -> NotificationHandler:
	if shared:
		return shared.push(notif)
	
	match failure_behavior:
		OnGlobalPushFail.QUEUE_FREE:
			notif.queue_free()
		OnGlobalPushFail.QUEUE_FREE:
			notif.free()
		OnGlobalPushFail.WAIT_FOR_SHARED:
			var handler: NotificationHandler = NotificationHandler.new()
			handler.notif = notif
			_global_notifications_on_hold.push_back(handler)
			return handler
	
	return null


static func _process_on_hold_notifications() -> void:
	if shared == null:
		return
	
	for on_hold in _global_notifications_on_hold:
		shared._process_handler.call_deferred(on_hold)


func _ready() -> void:
	if use_as_singleton:
		NotificationTray.shared = self


## Ignored groups will automatically be marked as read.
func ignore_group(group: Group) -> void:
	if group not in ignored_groups:
		ignored_groups.push_back(group)
		_mark_group_as_read(group)


## Ignored groups will automatically be marked as read.
func unignore_group(group: Group) -> void:
	ignored_groups.erase(group)


## Ignored groups will automatically be marked as read.
func is_group_ignored(group: Group) -> bool:
	return group in ignored_groups


var _queued_handlers: Array[NotificationHandler] = []
var _shown_handlers: Array[NotificationHandler] = []
var _group_cache: Dictionary = {}
func push(notif: Control) -> NotificationHandler:
	var handler: NotificationHandler = NotificationHandler.new()
	handler.notif = notif
	
	_process_handler.call_deferred(handler)
	
	return handler


## You don't need to call this if you just pushed a notification.
## This method is meant to be used if you you want to reuse an handler that
## went trough all the process of appearing, disappearing and squishing.
func reuse_handler(handler: NotificationHandler) -> void:
	_process_handler(handler)


## Always call deferred please.
func _process_handler(handler: NotificationHandler) -> void:
	if handler.group != null:
		if handler.group in ignored_groups:
			# TODO historic stuf
			handler.clean_up()
			return
		
		if _group_cache.get(handler.group, 0) >= handler.group.max_amount:
			match handler.group.overflow_bahavior:
				Group.OverflowBehavior.HOLD:
					_queued_handlers.append(handler)
				Group.OverflowBehavior.MARK_AS_READ:
					# TODO historic stuf
					pass
				Group.OverflowBehavior.DROP:
					notification_droped.emit(handler)
			return
	
	if _shown_handlers.size() >= maximum_shown_notifications:
		notification_pushed.emit(handler)
		handler.pushed_to.emit(self)
		_queued_handlers.append(handler)
		return
	
	if handler.notif.has_signal(&"marked_as_read"):
		handler.notif.marked_as_read.connect(
			_process_early_disappearance.bind(handler)
		)
	
	if handler.group and handler.notif.has_signal(&"group_marked_as_read"):
		handler.notif.group_marked_as_read.connect(
			_mark_group_as_read.bind(handler.group)
		)
		
	if handler.group and handler.notif.has_signal(&"group_ignored"):
		handler.notif.group_ignored.connect(
			ignore_group.bind(handler.group)
		)
	
	await _process_appearance(handler)
	
	if handler.is_marked_as_read:
		_process_disappearance(handler)
		return
	
	await get_tree().create_timer(
		handler.duration * handler.duration_multiplier,
	).timeout
	
	if handler.is_marked_as_read:
		return
	
	_process_disappearance(handler)


func _mark_group_as_read(group: Group) -> void:
	_queued_handlers = _queued_handlers.filter(
		func(handler: NotificationHandler) -> bool: return handler.group != group
	)
	
	for handler in _shown_handlers:
		if handler.group == group:
			_process_early_disappearance(handler)


func _process_appearance(handler: NotificationHandler) -> void:
	_apply_defaults_to(handler)
	_push_handler(handler)
	
	handler.notif.size_flags_horizontal = notifications_size_flags_horizontal
	handler.notif.hide()
	add_child(handler.notif)
	if gravity == Gravity.NORMAL:
		move_child(handler.notif, 0)
	
	if handler.audio_stream_player:
		handler.audio_stream_player.play()
	elif audio_stream_player:
		audio_stream_player.play()
	
	await _show_handler(handler)


func _process_early_disappearance(handler: NotificationHandler) -> void:
	handler.is_marked_as_read = true
	if handler.state == NotificationHandler.State.SHOWN:
		_process_disappearance(handler)


func _process_disappearance(handler: NotificationHandler) -> void:
	assert(handler.state == NotificationHandler.State.SHOWN)
	
	if handler.notif.has_signal(&"marked_as_read"):
		handler.notif.marked_as_read.disconnect(_process_early_disappearance)
	
	if handler.group and handler.notif.has_signal(&"group_marked_as_read"):
		handler.notif.group_marked_as_read.disconnect(_mark_group_as_read)
	
	if handler.group and handler.notif.has_signal(&"group_ignored"):
		handler.notif.group_ignored.disconnect(ignore_group)
	
	await _hide_handler(handler)
	
	await _squish_handler(handler)
	
	handler.clean_up()
	_shown_handlers.erase(handler)
	
	if _queued_handlers:
		_process_handler.call_deferred(_queued_handlers.pop_front())
	else:
		_rebuild_group_cache()


func _apply_defaults_to(handler: NotificationHandler) -> NotificationHandler:
	if handler.appear_animator == Callable():
		handler.appear_animator = _appear_animator
	if handler.disappear_animator == Callable():
		handler.disappear_animator = _disappear_animator
	if handler.duration == -1:
		handler.duration = notifications_duration
	if handler.duration_multiplier == -1:
		handler.duration_multiplier = notifications_duration_multiplier
	return handler


func _push_handler(new_handler: NotificationHandler) -> void:
	_shown_handlers.push_back(new_handler)
	_rebuild_group_cache()


func _rebuild_group_cache() -> void:
	_group_cache.clear()
	
	for handler in _shown_handlers:
		if handler.group != null:
			_group_cache[handler.group] = 1 + _group_cache.get(handler.group, 0)


func _show_handler(handler: NotificationHandler) -> void:
	notification_appearing.emit(handler)
	await handler.appear()
	notification_appeared.emit(handler)


func _hide_handler(handler: NotificationHandler) -> void:
	notification_disappearing.emit(handler)
	await handler.disappear()
	notification_disappeared.emit(handler)


func _squish_handler(handler) -> void:
	await handler.squish(notifications_squish_time)
	notification_squished.emit(handler)


func _appear_animator(notif: Control) -> void:
	match appear_animation_type:
		AppearAnimation.NONE:
			notif.show()
			return
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
			if notif.size_flags_horizontal & (SIZE_SHRINK_BEGIN|SIZE_SHRINK_CENTER|SIZE_SHRINK_END):
				fit_child_in_rect(notif, Rect2())
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
		DisappearAnimation.NONE:
			notif.hide()
			return
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
			if _shall_apply_disappear_animation_behind():
				notif.z_index = -1
			
			var container: Control = _build_container_for(notif)
			notif.show()
			
			await _apply_disappear_tween_properties(notif.create_tween().tween_property(
				notif,
				^"position",
				_get_offset_to_offscreen(disappear_animation_type, notif),
				disappear_animation_time,
			).from(Vector2(0, 0))).finished
			
			_remove_container(container, notif)
			
			if _shall_apply_disappear_animation_behind():
				notif.z_index = 0


func _apply_disappear_tween_properties(property_tweener: PropertyTweener) -> PropertyTweener:
	return property_tweener.set_trans(
		disappear_animation_trans,
	).set_ease(
		disappear_animation_ease,
	)


func _shall_apply_incomming_behind() -> bool:
	return (
		appear_animation_behind
		and appear_animation_type == AppearAnimation.COME_FROM_UP
		and gravity == Gravity.UPSIDE_DOWN
	)


func _shall_apply_disappear_animation_behind() -> bool:
	return (
		disappear_animation_behind
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


class Group extends RefCounted:
	## Can be used to alter behavior when multiple notifications of the same
	## group pushed to a tray. 
	
	## An indicative name.
	## [br][br]
	## [b]Warning:[/b] Different groups with the same name are [b]not[/b]
	## considered to be the same group. You have to use the same instance.
	var name: String
	func set_name(new_name: String) -> Group:
		name = new_name
		return self
	
	## When this amount of notification of the same group are reached in a
	## notification tray, a reaction occurs accroding to [member overflow_bahavior]
	var max_amount: int = 1
	func set_max_amount(new_max_amount: int) -> Group:
		max_amount = new_max_amount
		return self
	
	enum OverflowBehavior {
		## Notification will wait until another from the same group disappear.
		HOLD,
		MARK_AS_READ,
		## Will act as if the notification was not send.
		DROP,
	}
	var overflow_bahavior: OverflowBehavior = OverflowBehavior.HOLD
	func set_overflow_bahavior(new_overflow_bahavior: OverflowBehavior) -> Group:
		overflow_bahavior = new_overflow_bahavior
		return self


class NotificationHandler extends RefCounted:
	## Defines properties of a notification.
	
	## It does not always mean that it appeared.
	signal pushed_to(tray: NotificationTray)
	signal appearing()
	signal appeared()
	signal disappearing()
	signal disappeared()
	## Emitted when the notif disappeared and was squished to smoothly release room.
	## This mean it can be reused trough [method NotificationTray.reuse_handler].
	signal squished()
	
	enum EndBehavior {
		## Do nothing
		NONE,
		## Call [method Node.queue_free] on the notif.
		QUEUE_FREE,
		## Call [method Object.free] on the notif.
		FREE,
	}
	
	var audio_stream_player: AudioStreamPlayer
	func set_audio_stream_player(new_audio_stream_player: AudioStreamPlayer) -> NotificationHandler:
		audio_stream_player = new_audio_stream_player
		return self
	
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
	var group: Group
	func set_group(new_group: Group) -> NotificationHandler:
		group = new_group
		return self
	
	var duration: float = -1
	func set_duration(new_duration: float) -> NotificationHandler:
		duration = new_duration
		return self
	
	var duration_multiplier: float = -1
	func set_duration_multiplier(new_duration_multiplier: float) -> NotificationHandler:
		duration_multiplier = new_duration_multiplier
		return self
	
	var end_behavior: EndBehavior = EndBehavior.QUEUE_FREE
	func set_end_behavior(new_end_behavior: EndBehavior) -> NotificationHandler:
		end_behavior = new_end_behavior
		return self
	
	## Please avoid editing this property and prefer using a new hanlder created
	## trough a push method.
	var notif: Control
	
	enum State {
		ORPHAN,
		APPEARING,
		SHOWN,
		DISAPPEARING,
		SQUISHING,
		## This handler's notification has been freed.
		DEAD,
	}
	## [b]READ-ONLY[/b]
	var state: State = State.ORPHAN
	## [b]READ-ONLY[/b] for unadvised users
	var is_marked_as_read: bool = false
	
	
	func appear() -> void:
		is_marked_as_read = false
		state = State.APPEARING
		appearing.emit()
		await appear_animator.call(notif)
		appeared.emit()
		state = State.SHOWN
	
	func disappear() -> void:
		state = State.DISAPPEARING
		disappearing.emit()
		await disappear_animator.call(notif)
		disappeared.emit()
	
	func squish(duration: float) -> void:
		state = State.SQUISHING
		var dummy: Control = Control.new()
		notif.add_sibling(dummy)
		dummy.custom_minimum_size = notif.size
		notif.get_parent().remove_child(notif)
		
		await dummy.create_tween().tween_property(
			dummy,
			^"custom_minimum_size:y",
			0,
			duration,
		).finished
		
		dummy.queue_free()
		squished.emit()
	
	func clean_up() -> void:
		match end_behavior:
			EndBehavior.NONE:
				state = State.ORPHAN
				return
			EndBehavior.QUEUE_FREE:
				state = State.DEAD
				notif.queue_free()
			EndBehavior.FREE:
				state = State.DEAD
				notif.free()
