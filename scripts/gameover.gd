extends CanvasLayer
@onready var funnyImage = $FunnyImage
@export var imageArray:Array[Texture2D] = [
preload("res://graphics/Screens/GameOver/0_1.png"),
preload("res://graphics/Screens/GameOver/1_1.png"),
preload("res://graphics/Screens/GameOver/2_1.png"),
preload("res://graphics/Screens/GameOver/3_1.png"),
preload("res://graphics/Screens/GameOver/5_1.png")
]

func _ready():
	funnyImage.texture = imageArray[randi_range(0,imageArray.size()-1)]


# not doing the jumpscare easter egg, I don't wanna see fangames that have a chance of blowing out my ear drums
# also games auto closing is really annoying

func _on_timer_timeout():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
