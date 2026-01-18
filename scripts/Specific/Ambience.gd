extends AudioStreamPlayer3D
class_name Ambience

@export var ambientSounds = [
	preload("res://audio/SFX/Ambiences/fret.wav"),
	preload("res://audio/SFX/Ambiences/dulcimer.wav"),
	preload("res://audio/SFX/Ambiences/noise.wav"),
	preload("res://audio/SFX/Ambiences/creepy sound.wav"),
	preload("res://audio/SFX/Ambiences/tone.wav"),
]

# this gets called in global when an ai location is called
func play_ambience(setPosition :Vector3):
	var num = randi_range(0,49) # pick a number from 0 to 49
	# if not playing a sound and num is 0 (1/50 chance) play sound
	if !playing && num == 0:
		global_position = setPosition
		stream = ambientSounds[randi_range(0,ambientSounds.size()-1)]
		play()
	return
