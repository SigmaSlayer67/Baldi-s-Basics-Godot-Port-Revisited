# ATTENTION: Script done! (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
extends Node3D

var timeLeft : float = 30.0
var lifeSpan : float = 35.0 # lifeSpan should be above timeleft or otherwise it won't activate properly
var rang : bool = false
@export var audioRing : AudioStream = preload("res://audio/SFX/Items/bell.wav")

func _physics_process(delta : float) -> void:
	if timeLeft > 0.0:
		timeLeft -= delta
	elif !rang:# ring alarm
		rang = true
		# attract baldi to this location with a priority of 10
		if is_instance_valid(Global.baldi):
			Global.baldi.hear(global_position,10,false)
		# play the ringing sound
		# also increase audio range
		$Audio.unit_size = 100.0
		$Audio.stream = audioRing
		$Audio.play()
	if lifeSpan > 0.0: # decrease life span if greater then 0
		lifeSpan -= delta
	else:
		# delete after lifespan's over
		queue_free()
