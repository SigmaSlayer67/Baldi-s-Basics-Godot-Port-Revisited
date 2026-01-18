extends Character
class_name PlayTime

@export var active = false

var aim = Vector3.ZERO
@onready var playerChecker = $PlayerChecker
var canSeePlayer = false
var playerSpotted = false
@onready var sounds = $Sounds
var coolDown = 0.0
var playCool = 0.0
var jumpRopeStarted = false

@onready var playtime = $Playtime


# audio
@export var audNumbers = [preload("res://audio/Characters/Playtime/Numbers/PT_1.wav"),
preload("res://audio/Characters/Playtime/Numbers/PT_2.wav"),
preload("res://audio/Characters/Playtime/Numbers/PT_3.wav"),
preload("res://audio/Characters/Playtime/Numbers/PT_4.wav"),
preload("res://audio/Characters/Playtime/Numbers/PT_5.wav"),
preload("res://audio/Characters/Playtime/Numbers/Unused/PT_6.wav"),
preload("res://audio/Characters/Playtime/Numbers/Unused/PT_7.wav"),
preload("res://audio/Characters/Playtime/Numbers/Unused/PT_8.wav"),
preload("res://audio/Characters/Playtime/Numbers/Unused/PT_9.wav"),
preload("res://audio/Characters/Playtime/Numbers/Unused/PT_10.wav"),
]
@export var audRandom = [preload("res://audio/Characters/Playtime/PT_Laugh.wav"),
preload("res://audio/Characters/Playtime/PT_WannaPlay.wav")]

@export var audInstructions = preload("res://audio/Characters/Playtime/Unused/PT_Instructions.wav")
@export var audOops = preload("res://audio/Characters/Playtime/PT_Oops.wav")
@export var audLetsPlay = preload("res://audio/Characters/Playtime/PT_LetsPlay.wav")
@export var audCongrats = preload("res://audio/Characters/Playtime/PT_Congrats.wav")
@export var audReadyGo = preload("res://audio/Characters/Playtime/PT_ReadyGo.wav")
@export var audSad = preload("res://audio/Characters/Playtime/PT_Sad.wav")


var jumps = 0
var jumpDelay = 1.0

@onready var jumpropeAnimator = $JumpRope/JumpRope


func _ready():
	super()
	set_physics_process(active)
	visible = active

func activate():
	active = true
	set_physics_process(active)
	show()

func _physics_process(delta): 
	
	coolDown = move_toward(coolDown,0.0,delta)
	if playCool > 0:
		playCool = move_toward(playCool,0.0,delta)
		# stop being sad if sad
		if playCool <= 0:
			playtime.play("default")
	
	# Global.player.jumpRope
	
	if is_instance_valid(Global.player): # error prevention
		if !Global.player.jumpRope && speed == 0: # if player's not jump roping but playtime is still expecting it, then run the dissapointment routine
			dissapoint()
		if !Global.player.jumpRope:
			playerChecker.target_position = Global.player.global_position - global_position
			# check that the cast wasn't interupted
			canSeePlayer = (!playerChecker.is_colliding() && global_position.distance_to(Global.player.global_position) <= 80.0 && playCool <= 0)
		
			if canSeePlayer:
				target_player()
				playerSpotted = true # if playtime sees the player, chase them
			elif playerSpotted && coolDown <= 0:
				playerSpotted = false
				wander()
			elif get_real_velocity().length() <= 1.0 && coolDown <= 0.0:
				wander()
			jumpRopeStarted = false
		else:
			if !jumpRopeStarted:
				var destination = Global.player.global_position.slide(up_direction)-(global_position.slide(up_direction).direction_to(Global.player.global_position.slide(up_direction))*10.0)
				global_position = Vector3(destination.x,global_position.y,destination.z)
				jumpRopeStarted = true
			playCool = 15.0
	
	$PlayerCollider/CollisionShape3D.disabled = !$PlayerCollider/CollisionShape3D.disabled
	super(delta)
	velocity.y = 0.0


func wander():
	navAgent.target_position = Global.get_wander_point("hall_wander")# set random target based on targets
	speed = 15.0 # reset speed
	playerSpotted = false
	if !sounds.playing:
		sounds.stream = audRandom[randi_range(0,audRandom.size()-1)]
		sounds.play()
	coolDown = 1.0

func target_player():
	playtime.play("default") # no longer be sad
	navAgent.target_position = Global.player.global_position # target player
	speed = 20.0 # speed up
	coolDown = 0.2
	if !playerSpotted:
		sounds.stream = audLetsPlay
		sounds.play()
		playerSpotted = true

func dissapoint():
	playtime.play("sad")
	sounds.stream = audSad
	sounds.play()
	$JumpRope.hide()
	

func _on_player_collider_body_entered(body):
	if body is Player:
		if !body.jumpRope && playCool <= 0:
			speed = 0.0
			count_jumps()
			$JumpRope.show()
			body.jumpRope = true
			body.frozenPosition = body.global_position
			sounds.stream = audReadyGo
			sounds.play()
			await get_tree().create_timer(1.0,false).timeout
			jumpropeAnimator.play("Jump")


func _on_jump_rope_animation_finished(_anim_name):
	if !Global.player.jumpRope: return
	if Global.player.camera3D.v_offset <= 0.2: # failure
		jumps = 0 # reset jumps
		count_jumps()
		sounds.stream = audOops
		sounds.play()
		await get_tree().create_timer(2.0,false).timeout # Delay for 2 seconds to allow playtime to finish her line before the rope starts
		jumpropeAnimator.play("Jump")
	else: # success
		sounds.stream = audNumbers[jumps]
		sounds.play()
		jumps += 1
		count_jumps()
		await get_tree().create_timer(0.5,false).timeout
		if jumps >= 5:
			Global.player.jumpRope = false
			speed = 0.01 # give a bit of speed so the dissapointed routine doesn't run
			jumps = 0
			$JumpRope.hide()
			sounds.stream = audCongrats
			sounds.play()
		else:
			jumpropeAnimator.play("Jump")

func count_jumps():
	$JumpRope/Count.text = str(jumps)+"/5"

# cancel jumprope is scissors are used
func scissors() -> bool:
	# return true or false so the player knows is the scissors got used
	if Global.player.jumpRope:
		Global.player.jumpRope = false
		dissapoint()
		return true
	return false
