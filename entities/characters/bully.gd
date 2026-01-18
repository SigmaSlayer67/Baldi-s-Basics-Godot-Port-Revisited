extends StaticBody3D
class_name Bully

var waitTime = 65.7312
var activeTime = 0.0
var guilt = 0.0
var awake = false
var spoken = false


@export var active = false
@export var audTaunts = [preload("res://audio/Characters/Bully/B_TakeCandy.wav"),preload("res://audio/Characters/Bully/B_GiveGreat.wav")]
@export var audThanks = [preload("res://audio/Characters/Bully/B_TakeThat.wav"),preload("res://audio/Characters/Bully/B_Donation.wav")]
@export var audDenied = preload("res://audio/Characters/Bully/B_NoItems.wav")

@onready var sounds = $Sounds
@onready var playerChecker = $PlayerChecker


func _ready():
	Global.bully = self
	set_physics_process(active)
	visible = active

func activate():
	active = true
	set_physics_process(active)
	show()

func _physics_process(delta):
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

func wake_up():
	global_position = Global.get_wander_point("hall_wander")+Vector3(0,5,0) # set random target based on targets
	if is_instance_valid(Global.player):
		while global_position.distance_to(Global.player.global_position) <= 20.0: # go to different target if too close to player
			global_position = Global.get_wander_point("hall_wander")+Vector3(0,5,0)
	awake = true

func reset():
	global_position = Vector3(0,20,0)
	waitTime = randf_range(60,120) #Set the amount of time before the bully appears again
	awake = false
	activeTime = 0.0
	spoken = false
	guilt = 0.0


func _on_collider_body_entered(body):
	if body is Principal && guilt > 0.0: #If touching the principal and the bully is guilty
		body.bullySeen = false
		reset()
	elif body is Player:
		# check if player has items
		var hasItem = false
		for i in body.items:
			if i != 0:
				hasItem = true
		if !hasItem: # taunt if player doesn't have items
			sounds.stream = audDenied # "What, no items? No Items? No passsssss"
			sounds.play() 
		else:
			# select player inventory slot at random
			var getItem = randi_range(0,body.items.size()-1)
			# loop if the selected item is empty
			while (body.items[getItem] == 0):
				getItem = randi_range(0,body.items.size()-1)
			body.lose_item(getItem)
			sounds.stream = audThanks[randi_range(0,audThanks.size()-1)]
			sounds.play()
			reset()
