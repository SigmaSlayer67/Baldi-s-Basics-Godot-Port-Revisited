# ATTENTION: Script done! (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
extends Character
class_name FirstPrize

# first prize was the most annoying character to set up and even now I'm pretty sure they're still inaccurate

const TURN_SPEED : float = 15.0

@export var active : bool = false

@export var aud_found : Array[AudioStream] = [
	preload("res://audio/Characters/1stPrize/1PR_AmComing.wav"),
	preload("res://audio/Characters/1stPrize/1PR_ISeeYou.wav")
]
@export var aud_lost : Array[AudioStream] = [
	preload("res://audio/Characters/1stPrize/1PR_HaveLost.wav"),
	preload("res://audio/Characters/1stPrize/1PR_OhNo.wav")
]
@export var aud_hug : Array[AudioStream] = [
	preload("res://audio/Characters/1stPrize/1PR_IHug.wav"),
	preload("res://audio/Characters/1stPrize/1PR_Marry.wav")
]
@export var aud_random : Array[AudioStream] = [
	preload("res://audio/Characters/1stPrize/1PR_BeenProgrammed.wav"),
	preload("res://audio/Characters/1stPrize/1PR_AmLooking.wav")
]

var ang_diff : float = 0.0
var norm_speed : float = 5.0
var run_speed : float = 100.0
var current_speed : float = 0.0
var auto_break_cool : float = 0.0
var crazy_time : float = 0.0
# Unused variable
#var target_rotation : Transform3D
var cool_down : float = 0.0
# Unused variable
#var prev_speed : float = 0.0
var player_seen : bool = false
var hugAnnounced : bool = false

var playerReference : Player = null
var alive : bool = false # zoom prevention

var justhit : bool = false

@onready var playerChecker : RayCast3D = $PlayerChecker
@onready var sounds : AudioStreamPlayer3D = $Sounds
@onready var engine : AudioStreamPlayer3D = $Engine
@onready var bang : AudioStreamPlayer3D = $Bang

# Change "RaycCast3D to the name of your raycast object"
@onready var raycast : RayCast3D = $RayCast3D


func _ready() -> void:
	super()
	navAgent.target_position = global_position
	set_physics_process(active)
	visible = active
	cool_down = 1.0
	wander()
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	alive = true

func _physics_process(delta : float) -> void:
	cool_down = move_toward(cool_down,0.0,delta)
	
	#return
	if auto_break_cool > 0.0:
		auto_break_cool = move_toward(auto_break_cool,0.0,delta)
	
	var getPose : Vector3 = global_position-navAgent.get_next_path_position()
	ang_diff = angle_difference(rotation.y,atan2(getPose.x,getPose.z)) * 57.29578
	
	if crazy_time <= 0.0:
		if abs(ang_diff) < 5.0:
			rotate_y(angle_difference(rotation.y,atan2(getPose.x,getPose.z)))
			speed = current_speed
		else:
			rotate_y(deg_to_rad(TURN_SPEED) * sign(ang_diff) * delta)
			speed = 0.0
	else:
		speed = 0.0
		rotate_y(deg_to_rad(180.0) * delta)
		crazy_time = move_toward(crazy_time,0.0,delta)
	
	engine.pitch_scale = max(velocity.length() + 1.0  * delta,1.0)
	
	if not is_instance_valid(Global.player): 
		return
	
	playerChecker.rotation = -rotation
	playerChecker.target_position = Global.player.global_position - global_position
	if not playerChecker.is_colliding():
		if not player_seen and not sounds.playing:
			sounds.stream = random_audio_array_stream(aud_found)
			sounds.play()
		player_seen = true
		target_player()
		current_speed = run_speed
	else:
		current_speed = norm_speed
		if player_seen and cool_down <= 0.0:
			if not sounds.playing:
				sounds.stream = random_audio_array_stream(aud_lost)
				sounds.play()
			player_seen = false
			wander()
		elif velocity.length() <= 1.0 and cool_down <= 0.0 and (global_position - navAgent.target_position).length() < 5.0:
			wander()
	
	move_and_slide()
	
	# clamp position
	var lastTarget : Vector3 = navAgent.target_position # memorize target
	navAgent.target_position = global_position+(Vector3.UP*navAgent.path_height_offset) # set nav agent to self
	
	if not navAgent.is_target_reachable() and alive:
		var newTarget := Vector3(navAgent.get_final_position().x,global_position.y,navAgent.get_final_position().z)-global_position # clamp position
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
	
	if is_instance_valid(playerReference) and velocity.dot(-global_basis.z) > 5.0:
		# check they aren't using boots
		if not playerReference.boots:
			playerReference.hugging = true
			playerReference.failSafe = 1.0
			playerReference.velocity = velocity*delta*60.0
	#super(delta)


func _on_player_collider_body_entered(body : Node3D) -> void:
	if body is Player:
		if not sounds.playing and not hugAnnounced:
			sounds.stream = random_audio_array_stream(aud_hug)
			sounds.play()
			hugAnnounced = true
		playerReference = body



func _on_player_collider_body_exited(_body : Node3D) -> void:
	auto_break_cool = 1.0
	playerReference = null


func activate() -> void:
	active = true
	set_physics_process(active)
	show()


func wander() -> void:
	# set random target based on targets
	navAgent.target_position = Global.get_wander_point(&"hall_wander")
	hugAnnounced = false
	var num : int = randi_range(0, 9)
	if num == 0 and cool_down <= 0.0 and sounds.playing:
		sounds.stream = random_audio_array_stream(aud_random)
		sounds.play()
	cool_down = 1.0


func target_player() -> void:
	navAgent.target_position = Global.player.global_position
	cool_down = 0.5


func scissors() -> bool:
	# return true or false so the player knows if to use the item up
	if crazy_time <= 0.0:
		# on scissors used, set crazy time to 15 seconds
		crazy_time = 15.0
		return true
	return false


func random_audio_array_stream(audio_array: Array[AudioStream]) -> AudioStream:
	var random_audio_stream : AudioStream = audio_array[randi_range(0, audio_array.size() - 1)]
	return random_audio_stream
