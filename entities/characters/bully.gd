# ATTENTION: Script done! (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
extends StaticBody3D
class_name Bully

var waitTime : float = 65.7312
var activeTime : float = 0.0
var guilt : float = 0.0
var awake : bool = false
var spoken : bool = false


@export var active : bool = false
@export var audTaunts : Array[AudioStream] = [preload("res://audio/Characters/Bully/B_TakeCandy.wav"),preload("res://audio/Characters/Bully/B_GiveGreat.wav")]
@export var audThanks : Array[AudioStream] = [preload("res://audio/Characters/Bully/B_TakeThat.wav"),preload("res://audio/Characters/Bully/B_Donation.wav")]
@export var audDenied : AudioStream = preload("res://audio/Characters/Bully/B_NoItems.wav")

@onready var sounds : AudioStreamPlayer = $Sounds
@onready var playerChecker : RayCast3D = $PlayerChecker


func _ready() -> void:
	Global.bully = self
	set_physics_process(active)
	visible = active

func activate() -> void:
	active = true
	set_physics_process(active)
	show()

func _physics_process(delta : float) -> void:
	if waitTime > 0.0:
		waitTime = move_toward(waitTime,0.0,delta)
	elif !awake:
		wake_up() # wake up bully
	if is_instance_valid(Global.player):
		if awake: # if the bully is on the map
			activeTime += delta # increase active time
			if activeTime >= 180.0 && global_position.distance_to(Global.player.global_position) >= 120.0: # If the bully has been in the map for a long time and the player is far away
				reset() # Reset the bully
	guilt = move_toward(guilt,0.0,delta)
	
	playerChecker.target_position = Global.player.global_position - global_position
	if !playerChecker.is_colliding() && awake && global_position.distance_to(Global.player.global_position) <= 30.0:
		if !spoken: # If the bully hasn't already spoken
			# Get a taunt sound
			sounds.stream = audTaunts[randi_range(0,audTaunts.size()-1)]
			sounds.play()
			spoken = true # Sets spoken to true, preventing the bully from talking again
		guilt = 10.0 # Makes the bully guilty for "Bullying in the halls"

func wake_up() -> void:
	global_position = Global.get_wander_point(&"hall_wander")+Vector3(0.0,5.0,0.0) # set random target based on targets
	if is_instance_valid(Global.player):
		while global_position.distance_to(Global.player.global_position) <= 20.0: # go to different target if too close to player
			global_position = Global.get_wander_point(&"hall_wander")+Vector3(0.0,5.0,0.0)
	awake = true

func reset() -> void:
	global_position = Vector3i(0,20,0)
	waitTime = randf_range(60.0, 120.0) #Set the amount of time before the bully appears again
	awake = false
	activeTime = 0.0
	spoken = false
	guilt = 0.0


func _on_collider_body_entered(body : Node3D) -> void:
	if body is Principal && guilt > 0.0: #If touching the principal and the bully is guilty
		body.bullySeen = false
		reset()
	elif body is Player:
		# check if player has items
		var hasItem : bool = false
		for i : int in body.items:
			if i != 0:
				hasItem = true
		if !hasItem: # taunt if player doesn't have items
			sounds.stream = audDenied # "What, no items? No Items? No passsssss"
			sounds.play() 
		else:
			# select player inventory slot at random
			var getItem : int = randi_range(0,body.items.size()-1)
			# loop if the selected item is empty
			while (body.items[getItem] == 0):
				getItem = randi_range(0,body.items.size()-1)
			body.lose_item(getItem)
			sounds.stream = audThanks[randi_range(0,audThanks.size()-1)]
			sounds.play()
			reset()
