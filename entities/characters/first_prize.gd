extends Character
class_name FirstPrize

# first prize was the most annoying character to set up and even now I'm pretty sure they're still inaccurate

@export var active = false

const TURN_SPEED = 15.0

var angDiff = 0.0
var normSpeed = 5.0
var runSpeed = 100.0
var currentSpeed = 0.0
var autoBreakCool = 0.0
var crazyTime = 0.0
var targetRotation : Transform3D
var coolDown = 0.0
var prevSpeed = 0.0
var playerSeen = false
var hugAnnounced = false
@export var audFound = [preload("res://audio/Characters/1stPrize/1PR_AmComing.wav"), preload("res://audio/Characters/1stPrize/1PR_ISeeYou.wav")]
@export var audLost = [preload("res://audio/Characters/1stPrize/1PR_HaveLost.wav"), preload("res://audio/Characters/1stPrize/1PR_OhNo.wav")]
@export var audHug = [preload("res://audio/Characters/1stPrize/1PR_IHug.wav"), preload("res://audio/Characters/1stPrize/1PR_Marry.wav")]
@export var audRandom = [preload("res://audio/Characters/1stPrize/1PR_BeenProgrammed.wav"), preload("res://audio/Characters/1stPrize/1PR_AmLooking.wav")]

@onready var playerChecker = $PlayerChecker
@onready var sounds = $Sounds
@onready var engine = $Engine
@onready var bang = $Bang

@onready var raycast = $RayCast3D #Change "RaycCast3D to the name of your raycast object"

var playerReference = null
var alive = false # zoom prevention

var justhit = false

func _ready():
	super()
	navAgent.target_position = global_position
	set_physics_process(active)
	visible = active
	coolDown = 1.0
	wander()
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	alive = true

func _physics_process(delta):
	coolDown = move_toward(coolDown,0.0,delta)
	
	#return
	if autoBreakCool > 0.0:
		autoBreakCool = move_toward(autoBreakCool,0.0,delta)
	
	var getPose = global_position-navAgent.get_next_path_position()
	angDiff = angle_difference(rotation.y,atan2(getPose.x,getPose.z)) * 57.29578
	
	if crazyTime <= 0.0:
		if abs(angDiff) < 5.0:
			rotate_y(angle_difference(rotation.y,atan2(getPose.x,getPose.z)))
			speed = currentSpeed
		else:
			rotate_y(deg_to_rad(TURN_SPEED) * sign(angDiff) * delta)
			speed = 0.0
	else:
		speed = 0.0
		rotate_y(deg_to_rad(180.0) * delta)
		crazyTime = move_toward(crazyTime,0.0,delta)
	
	engine.pitch_scale = max(velocity.length() + 1.0  * delta,1.0)
	
	if !is_instance_valid(Global.player): return
	
	playerChecker.rotation = -rotation
	playerChecker.target_position = Global.player.global_position - global_position
	if !playerChecker.is_colliding():
		if !playerSeen && !sounds.playing:
			sounds.stream = audFound[randi_range(0,audFound.size()-1)]
			sounds.play()
		playerSeen = true
		target_player()
		currentSpeed = runSpeed
	else:
		currentSpeed = normSpeed
		if playerSeen && coolDown <= 0.0:
			if !sounds.playing:
				sounds.stream = audLost[randi_range(0,audLost.size()-1)]
				sounds.play()
			playerSeen = false
			wander()
		elif velocity.length() <= 1.0 && coolDown <= 0.0 && (global_position - navAgent.target_position).length() < 5.0:
			wander()
	
	move_and_slide()
	
	# clamp position
	var lastTarget = navAgent.target_position # memorize target
	navAgent.target_position = global_position+(Vector3.UP*navAgent.path_height_offset) # set nav agent to self
	
	if !navAgent.is_target_reachable() && alive:
		var newTarget = Vector3(navAgent.get_final_position().x,global_position.y,navAgent.get_final_position().z)-global_position # clamp position
		if newTarget.length() > 0.1:
			velocity = velocity.slide(newTarget.normalized()) # adjust velocity to slide against the barrier (prevents driving constantly into walls)
		
	navAgent.target_position = lastTarget
	
	if raycast.is_colliding(): 
		if not justhit:
			justhit = true
			if velocity.length() >= 30.0: bang.play()
		velocity = Vector3.ZERO
		speed = 0.0
	else:
		justhit = false
		# set movement direction
		velocity = velocity.move_toward((-global_basis.z*(speed)),delta * 10.0)
	
	
	if is_instance_valid(playerReference) && velocity.dot(-global_basis.z) > 5.0:
		# check they aren't using boots
		if !playerReference.boots:
			playerReference.hugging = true
			playerReference.failSafe = 1.0
			playerReference.velocity = velocity*delta*60.0
	#super(delta)

func activate():
	active = true
	set_physics_process(active)
	show()


func wander():
	navAgent.target_position = Global.get_wander_point("hall_wander")# set random target based on targets
	hugAnnounced = false
	var num = randi_range(0,9)
	if num == 0 && coolDown <= 0.0 && sounds.playing:
		sounds.stream = audRandom[randi_range(0,audRandom.size()-1)]
		sounds.play()
	coolDown = 1.0


func target_player():
	navAgent.target_position = Global.player.global_position
	coolDown = 0.5



func _on_player_collider_body_entered(body):
	if body is Player:
		if !sounds.playing && !hugAnnounced:
			sounds.stream = audHug[randi_range(0,audHug.size()-1)]
			sounds.play()
			hugAnnounced = true
		playerReference = body



func _on_player_collider_body_exited(_body):
	autoBreakCool = 1.0
	playerReference = null


func scissors() -> bool:
	# return true or false so the player knows if to use the item up
	if crazyTime <= 0.0:
		# on scissors used, set crazy time to 15 seconds
		crazyTime = 15.0
		return true
	return false
