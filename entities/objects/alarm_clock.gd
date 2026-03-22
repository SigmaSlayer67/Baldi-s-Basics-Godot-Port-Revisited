# ATTENTION: Script donenot  (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
extends Node3D

var time_left : float = 30.0
var life_span : float = 35.0 # life_span should be above timeleft or otherwise it won't activate properly
var rang : bool = false
@export var audio_ring : AudioStream = preload("res://audio/SFX/Items/bell.wav")

func _physics_process(delta : float) -> void:
	if time_left > 0.0:
		time_left -= delta
	elif not rang:# ring alarm
		rang = true
		# attract baldi to this location with a priority of 10
		if is_instance_valid(Global.baldi):
			Global.baldi.hear(global_position,10,false)
		# play the ringing sound
		# also increase audio range
		$Audio.unit_size = 100.0
		$Audio.stream = audio_ring
		$Audio.play()
	if life_span > 0.0: # decrease life span if greater then 0
		life_span -= delta
	else:
		# delete after lifespan's over
		queue_free()
