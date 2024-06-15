@tool
class_name BaseNotification
extends PanelContainer


#enum IconPosition {
	#NORMAL,
	#TITLE_INLINE,
	#DESCIPTION_INLINE,
#}
## If the next field is unused, the corresponding control will be hiden.
@export var hide_if_empty_title: bool = true
@export var title: String = "":
	set(new):
		title = new
		_adapt_to_title()
@export var title_label: Label = null:
	set(new):
		title_label = new
		_adapt_to_title()
## If the next field is unused, the corresponding control will be hiden.
@export var hide_if_empty_description: bool = true
@export var description: String = "":
	set(new):
		description = new
		_adapt_to_description()
@export var description_label: RichTextLabel = null:
	set(new):
		description_label = new
		_adapt_to_description()
## If the next field is unused, the corresponding control will be hiden.
@export var hide_if_null_icon: bool = true
@export var icon_texture: Texture = preload("res://icon.svg"):
	set(new):
		icon_texture = new
		_adapt_to_icon_texture()
@export var icon_rect: TextureRect = null:
	set(new):
		icon_rect = new
		_adapt_to_icon_texture()
#@export var icon_position: IconPosition = IconPosition.NORMAL:
	#set(new):
		#icon_position = new
		#_adapt_to_icon_position()


#region Chainable setters
func set_title(new_title: String) -> BaseNotification:
	title = new_title
	return self


func set_description(new_description: String) -> BaseNotification:
	description = new_description
	return self


func set_icon_texture(new_icon_texture: Texture) -> BaseNotification:
	icon_texture = new_icon_texture
	return self
#endregion


#@onready var main_container: HBoxContainer = $MainContainer
#@onready var title_container: HBoxContainer = $MainContainer/VBoxContainer/TitleContainer
#@onready var desc_container: HBoxContainer = $MainContainer/VBoxContainer/DescContainer


func _ready() -> void:
	if Engine.is_editor_hint():
		if has_node("%Title") and not title_label:
			title_label = %Title
		if has_node("%Description") and not description_label:
			description_label = %Description
		if has_node("%Icon") and not icon_rect:
			icon_rect = %Icon
	else:
		_adapt_to_title()
		_adapt_to_description()
		_adapt_to_icon_texture()
		#_adapt_to_icon_position()


func _adapt_to_title() -> void:
	if title_label:
		if title:
			title_label.text = title
			title_label.show()
		elif hide_if_empty_title:
			title_label.hide()


func _adapt_to_description() -> void:
	if description_label:
		if description:
			description_label.text = description
			description_label.show()
		elif hide_if_empty_description:
			description_label.hide()


func _adapt_to_icon_texture() -> void:
	if icon_rect:
		if icon_texture:
			icon_rect.texture = icon_texture
			icon_rect.show()
		elif hide_if_null_icon:
			icon_rect.hide()


#func _adapt_to_icon_position() -> void:
	#if not is_node_ready():
		#return
	#
	#match icon_position:
		#IconPosition.NORMAL:
			#_move_icon_in(main_container)
		#IconPosition.TITLE_INLINE:
			#_move_icon_in(title_container)
		#IconPosition.DESCIPTION_INLINE:
			#_move_icon_in(desc_container)
#
#
#func _move_icon_in(container: Node) -> void:
	#icon_rect.reparent(container, false)
	#container.move_child(icon_rect, 0)
	#icon_rect.owner = self
