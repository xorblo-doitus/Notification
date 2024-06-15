@tool
extends BaseNotification


const titles = [
	"GG",
	"LOL",
	"Awesome title",
	"You did it!",
	"I am a very very long title and I should be shortened... Yes I should really...",
]

const descriptions = [
	"Awesome description that spends some lines.",
	"I am a very very long description and I should be shortened... Yes I should really... But I still keep growing more and more because the dev need a very long description to stress test the UI.",
]


func _ready() -> void:
	#custom_minimum_size.y = randi_range(150, 200)
	add_theme_constant_override("icon_size", randi_range(0, 1))
	title = titles.pick_random()
	description = descriptions.pick_random()
