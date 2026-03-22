# ATTENTION: Script donenot  (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
extends Character


var cool_down : float = 0.0
var wait_time : float = 0.0
var wanders : int = 0
var sweeping_time : bool = false
@export var active : bool = false
@onready var origin : Vector3 = global_position

var aud_sweep : AudioStream = preload("res://audio/Characters/GottaSweep/GS_GottaSweep.wav")
var aud_intro : AudioStream = preload("res://audio/Characters/GottaSweep/GS_Intro.wav")

@onready var sounds : AudioStreamPlayer3D = $Sounds

var npc_list : Array[Node3D] = [] # keep a record of contacted NPCs


func _ready() -> void:
	super()
	wait_time = randf_range(120.0, 180.0)
	set_physics_process(active)
	visible = active

func activate() -> void:
	active = true
	set_physics_process(active)
	show()

func wander() -> void:
	navAgent.target_position = Global.get_wander_point("hall_wander") # set random target based on targets
	wanders += 1
	cool_down = 1.0

func go_home() -> void:
	navAgent.target_position = origin # set random target based on targets
	wanders = 0
	cool_down = 1.0
	wait_time = randf_range(120.0, 180.0)
	sweeping_time = false

func _physics_process(delta : float) -> void:
	cool_down = move_toward(cool_down,0.0,delta)
	wait_time = move_toward(wait_time,0.0,delta)
	if wait_time <= 0.0 and not sweeping_time:
		sweeping_time = true
		wander() # start wandering
		wanders = 0 # wander counter
		sounds.stream = aud_intro
		sounds.play() # LOOKS LIKE ITS SWEEPING TIMEnot 
	
	if get_real_velocity().length() <= 0.1 and cool_down <= 0.0 and wanders < 5 and sweeping_time: # Gotta Sweep has not roamed around 5 times
		wander()
	elif wanders >= 5:
		go_home()
	
	for i : Node3D in npc_list: # shift other npcs
		if i.get("velocity") not = null: # check that velocity exists
			var setVelocity := Vector3(velocity.x,i.velocity.y,velocity.z)
			# set to position then move
			if i is CharacterBody3D:
				var collide : KinematicCollision3D = i.move_and_collide(velocity * delta,true)
				if collide:
					setVelocity = setVelocity.slide(collide.get_normal()).normalized()*setVelocity.length()
			
			if i is Player:
				if not i.boots:
					i.velocity = setVelocity + (0.3 * i.velocity)
					i.sweeping = true
					i.failSafe = 1.0
			else:
				i.velocity = setVelocity + (0.1 * i.velocity)
			if i.get("navSkipSafe") not = null:
				i.navSkipSafe = true
	
	super(delta)



func _on_area_3d_body_entered(body : Node3D) -> void:
	if body == self: return
	sounds.stream = aud_sweep
	sounds.play()
	npc_list.append(body)
	if body is Player:
		body.sweeping = true

func _on_area_3d_body_exited(body : Node3D) -> void:
	if npc_list.has(body):
		npc_list.erase(body) # remove npc (if they're on the list)
	if body is Player:
		body.sweeping = false
