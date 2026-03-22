# ATTENTION: Script done! (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
extends AudioStreamPlayer3D
class_name Ambience

@export var ambient_sounds : Array[AudioStream] = [
	preload("res://audio/SFX/Ambiences/fret.wav"),
	preload("res://audio/SFX/Ambiences/dulcimer.wav"),
	preload("res://audio/SFX/Ambiences/noise.wav"),
	preload("res://audio/SFX/Ambiences/creepy sound.wav"),
	preload("res://audio/SFX/Ambiences/tone.wav"),
]

# this gets called in global when an ai location is called
func play_ambience(set_position : Vector3) -> void:
	var num : int = randi_range(0,49) # pick a number from 0 to 49
	# if not playing a sound and num is 0 (1/50 chance) play sound
	if !playing && num == 0:
		global_position = set_position
		stream = ambient_sounds[randi_range(0,ambient_sounds.size()-1)]
		play()
	return
