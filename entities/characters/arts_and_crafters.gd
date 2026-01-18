extends Character
class_name Crafters

@export var active = false

@export var audCrafterLoop = preload("res://audio/Characters/ArtsAndCrafters/CFT_Loop.wav")

@export var angrySprite = preload("res://graphics/Characters/ArtsAndCrafters/Crafters_Ohno.png")

@export var noteBookAnger = 7

var angry = false
var gettingAngry = false
var anger = 0.0
var forceShowTime = 0.0

@onready var sounds = $Sounds
@onready var sprite = $ArtsAndCrafters
@onready var playerChecker = $PlayerChecker
@onready var visibilityChecker = $VisibilityChecker


func _ready():
	Global.crafters = self
	super()
	set_physics_process(active)
	visible = active

func activate():
	active = true
	set_physics_process(active)
	show()

func _process(delta):
	forceShowTime = move_toward(forceShowTime,0.0,delta)
	if gettingAngry: # if arts is getting angry
		anger += delta # Increase anger
		if anger >= 1.0 && !angry: # If anger is greater then 1 and arts isn't angry
			angry = true # Get angry
			sounds.play() # scream
			sprite.texture = angrySprite
	elif anger > 0.0: # if angeer is greater then 0, decrease
		anger = move_toward(anger,0.0,delta)

func _physics_process(delta):
	if !angry: # if not angry
		if is_instance_valid(Global.player):
			if (global_position.distance_to(navAgent.get_final_position()) <= 20.0 && global_position.distance_to(Global.player.global_position) >= 60) || forceShowTime > 0.0: # if close to the player and force showtime is less then 0
				visible = true # show
			else:
				visible = false # hide
	else:
		speed += 60.0 * delta # increase the speed
		navAgent.target_position = Global.player.global_position
	
	if Global.noteBooks >= noteBookAnger: # If the player has more then the note book count 
		playerChecker.target_position = (Global.player.global_position - global_position).slide(Vector3.UP)
		playerChecker.force_raycast_update()
		if !playerChecker.is_colliding() && visibilityChecker.is_on_screen() && visible: # if Arts is visible, and active and sees player
			gettingAngry = true # start getting angry
		else:
			gettingAngry = false # stop being angry
	super(delta)

func give_location(location, flee):
	if !angry && active:
		navAgent.target_position = location
		playerChecker.target_position = (Global.player.global_position - global_position).slide(Vector3.UP)
		playerChecker.force_raycast_update()
		if flee && !playerChecker.is_colliding(): # show if fleeing and line of sight isn't broken
			forceShowTime = 3.0 # Make arts appear in 3 seconds


# play full whoosh sound if rotating
func _on_sounds_finished():
	sounds.stream = audCrafterLoop
	sounds.play()



func _on_player_collider_body_entered(body):
	if angry:
		body.global_position = Vector3(0.0,body.global_position.y,75.0) # Teleport the player
		if is_instance_valid(Global.baldi):
			Global.baldi.global_position = Vector3(0.0, Global.baldi.global_position.y, 120.0) # Teleport Baldi
			# Make the player look at baldi
			body.look_at(Vector3(Global.baldi.global_position.x,body.global_position.y,Global.baldi.global_position.z),body.up_direction)
		
		queue_free() # despawn
