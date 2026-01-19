extends CanvasLayer
@onready var funnyImage : TextureRect = $FunnyImage
@export var imageArray: Array[Texture2D] = [
preload("res://graphics/Screens/GameOver/0_1.png"),
preload("res://graphics/Screens/GameOver/1_1.png"),
preload("res://graphics/Screens/GameOver/2_1.png"),
preload("res://graphics/Screens/GameOver/3_1.png"),
preload("res://graphics/Screens/GameOver/5_1.png")
]

func _ready() -> void:
	funnyImage.texture = imageArray.pick_random()

# not doing the jumpscare easter egg, I don't wanna see fangames that have a chance of blowing out my ear drums
# also games auto closing is really annoying
func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
