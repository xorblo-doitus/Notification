# Notification

An UI helping adding notifications to show for example errors, achievments...


# Development Status

Early development


## Installation

Download only `res://addons/notification`.


## How to use

Instantiate `res://addons/notification/notification_traynotification_tray.tscn` somewhere in your UI.

Push notifications to it. It can either be custom controls, the base notification in
`res://addons/notification/notifications/base_notification.tscn` or
a custom control using BaseNotification as class. (But notifications under
`/addon/notification/notifications` are only helpers/examples, you are not forced to use them.)

If the pushed notification has a `marked_as_read` signal,
the notification will be closed early when this signal is emitted.

If the pushed notification has a `group_marked_as_read` signal,
all notifications of the same group will be closed early
when this signal is emitted.


## Theme type variations

- NotificationTray (inheriting VBoxContainer)
- BaseNotification (inheriting PanelContainer)

See also "/addons/notification/example_theme.tres".


## Godot version

Godot 4.2, may not work with other 4.x, wont work with 3.x
