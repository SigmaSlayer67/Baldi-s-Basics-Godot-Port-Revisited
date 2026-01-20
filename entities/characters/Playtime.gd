extends Character
class_name PlayTime

@export var active : bool = false

# audio
@export var audNumbers : Array[AudioStream] = [preload("res://audio/Characters/Playtime/Numbers/PT_1.wav"),
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
@export var audRandom : Array[AudioStream] = [preload("res://audio/Characters/Playtime/PT_Laugh.wav"),
preload("res://audio/Characters/Playtime/PT_WannaPlay.wav")]

@export var audInstructions : AudioStream = preload("res://audio/Characters/Playtime/Unused/PT_Instructions.wav")
@export var audOops : AudioStream = preload("res://audio/Characters/Playtime/PT_Oops.wav")
@export var audLetsPlay : AudioStream = preload("res://audio/Characters/Playtime/PT_LetsPlay.wav")
@export var audCongrats : AudioStream = preload("res://audio/Characters/Playtime/PT_Congrats.wav")
@export var audReadyGo : AudioStream = preload("res://audio/Characters/Playtime/PT_ReadyGo.wav")
@export var audSad : AudioStream = preload("res://audio/Characters/Playtime/PT_Sad.wav")

# general
# We are just using := since it is redundantin this case  for the reader/compiler to type this literally
# So everytime you see a class being used like this, just do :=
var aim := Vector3.ZERO
# For everything else, you can statically type these as is
var can_see_player : bool = false
var player_spotted : bool = false
var cool_down : float = 0.0
var play_cool : float = 0.0
var jump_rope_started : bool = false
var jumps : int = 0
var jump_delay : float = 1.0

# onready
@onready var playtime : AnimatedSprite3D = $Playtime
@onready var sounds : AudioStreamPlayer3D = $Sounds
@onready var player_checker : RayCast3D = $PlayerChecker
@onready var jumpropeAnimator : AnimationPlayer  = $JumpRope/JumpRope


func _ready() -> void:
	super()
	set_physics_process(active)
	visible = active

func activate() -> void:
	active = true
	set_physics_process(active)
	show()

func _physics_process(delta : float) -> void: 
	
	cool_down = move_toward(cool_down,0.0,delta)
	if play_cool > 0:
		play_cool = move_toward(play_cool,0.0,delta)
		# stop being sad if sad
		if play_cool <= 0:
			playtime.play("default")
	
	# Global.player.jumpRope
	
	if is_instance_valid(Global.player): # error prevention
		if !Global.player.jumpRope && speed == 0: # if player's not jump roping but playtime is still expecting it, then run the dissapointment routine
			dissapoint()
		if !Global.player.jumpRope:
			player_checker.target_position = Global.player.global_position - global_position
			# check that the cast wasn't interupted
			can_see_player = (!player_checker.is_colliding() && global_position.distance_to(Global.player.global_position) <= 80.0 && play_cool <= 0)
		
			if can_see_player:
				target_player()
				player_spotted = true # if playtime sees the player, chase them
			elif player_spotted && cool_down <= 0:
				player_spotted = false
				wander()
			elif get_real_velocity().length() <= 1.0 && cool_down <= 0.0:
				wander()
			jump_rope_started = false
		else:
			if !jump_rope_started:
				var destination : Vector3 = Global.player.global_position.slide(up_direction)-(global_position.slide(up_direction).direction_to(Global.player.global_position.slide(up_direction))*10.0)
				global_position = Vector3(destination.x,global_position.y,destination.z)
				jump_rope_started = true
			play_cool = 15.0
	
	$PlayerCollider/CollisionShape3D.disabled = !$PlayerCollider/CollisionShape3D.disabled
	super(delta)
	velocity.y = 0.0


func wander() -> void:
	navAgent.target_position = Global.get_wander_point("hall_wander")# set random target based on targets
	speed = 15.0 # reset speed
	player_spotted = false
	if !sounds.playing:
		sounds.stream = audRandom[randi_range(0,audRandom.size()-1)]
		sounds.play()
	cool_down = 1.0

func target_player() -> void:
	playtime.play("default") # no longer be sad
	navAgent.target_position = Global.player.global_position # target player
	speed = 20.0 # speed up
	cool_down = 0.2
	if !player_spotted:
		sounds.stream = audLetsPlay
		sounds.play()
		player_spotted = true

func dissapoint() -> void:
	playtime.play("sad")
	sounds.stream = audSad
	sounds.play()
	$JumpRope.hide()
	

func _on_player_collider_body_entered(body : Node3D) -> void:
	if body is Player:
		if !body.jumpRope && play_cool <= 0:
			speed = 0.0
			count_jumps()
			$JumpRope.show()
			body.jumpRope = true
			body.frozenPosition = body.global_position
			sounds.stream = audReadyGo
			sounds.play()
			await get_tree().create_timer(1.0,false).timeout
			jumpropeAnimator.play("Jump")


func _on_jump_rope_animation_finished(_anim_name : StringName) -> void:
	if !Global.player.jumpRope: return
	if Global.player.camera3D.v_offset <= 0.2: # failure
		jumps = 0 # reset jumps
		count_jumps()
		sounds.stream = audOops
		sounds.play()
		# Delay for 2 seconds to allow playtime to finish her line before the rope starts
		await get_tree().create_timer(2.0,false).timeout
		jumpropeAnimator.play("Jump")
	else: # success
		sounds.stream = audNumbers[jumps]
		sounds.play()
		jumps += 1
		count_jumps()
		await get_tree().create_timer(0.5,false).timeout
		if jumps >= 5:
			Global.player.jumpRope = false
			# give a bit of speed so the dissapointed routine doesn't run
			speed = 0.01
			jumps = 0
			$JumpRope.hide()
			sounds.stream = audCongrats
			sounds.play()
		else:
			jumpropeAnimator.play("Jump")

func count_jumps() -> void:
	$JumpRope/Count.text = str(jumps)+"/5"

# cancel jumprope is scissors are used
func scissors() -> bool:
	# return true or false so the player knows is the scissors got used
	if Global.player.jumpRope:
		Global.player.jumpRope = false
		dissapoint()
		return true
	return false
