extends Area3D

@export var open_sprite = preload("res://graphics/SchoolHouse/PickUps/TapePlayers/TapePlayerOpen.png")
@export var close_sprite = preload("res://graphics/SchoolHouse/PickUps/TapePlayers/TapePlayerclosed.png")


func use_tape(_player : Player):
	if is_instance_valid(Global.baldi):
		Global.baldi.activate_anti_hearing(30.0) # anti hearing for 30 seconds
	$Audio.stop()
	$Audio.play()
	$Player.texture = close_sprite


func _on_audio_finished():
	$Player.texture = open_sprite
