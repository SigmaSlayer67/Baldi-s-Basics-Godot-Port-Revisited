# ATTENTION: Script done! (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
# ATTENTION: Script done! (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
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
	# Tried getting rid of the old way of randomizing the output with randi
	# instead i just used pick_random() which for this case is more readable and appropiate
	funnyImage.texture = imageArray.pick_random()

# not doing the jumpscare easter egg, I don't wanna see fangames that have a chance of blowing out my ear drums
# also games auto closing is really annoying
# ... Prepare yourself because i have an idea fellow
func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
