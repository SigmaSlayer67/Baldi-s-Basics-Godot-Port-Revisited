extends Character


var coolDown = 0.0
var waitTime = 0.0
var wanders = 0
var sweepinTime = false
@export var active = false
@onready var origin = global_position

var audSweep = preload("res://audio/Characters/GottaSweep/GS_GottaSweep.wav")
var audIntro = preload("res://audio/Characters/GottaSweep/GS_Intro.wav")

@onready var sounds = $Sounds

var npcList = [] # keep a record of contacted NPCs


func _ready():
	super()
	waitTime = randf_range(120,180)
	set_physics_process(active)
	visible = active

func activate():
	active = true
	set_physics_process(active)
	show()

func wander():
	navAgent.target_position = Global.get_wander_point("hall_wander") # set random target based on targets
	wanders += 1
	coolDown = 1.0

func go_home():
	navAgent.target_position = origin # set random target based on targets
	wanders = 0
	coolDown = 1.0
	waitTime = randf_range(120,180)
	sweepinTime = false

func _physics_process(delta):
	coolDown = move_toward(coolDown,0.0,delta)
	waitTime = move_toward(waitTime,0.0,delta)
	if waitTime <= 0.0 && !sweepinTime:
		sweepinTime = true
		wander() # start wandering
		wanders = 0 # wander counter
		sounds.stream = audIntro
		sounds.play() # LOOKS LIKE ITS SWEEPING TIME!
	
	if get_real_velocity().length() <= 0.1 && coolDown <= 0.0 && wanders < 5 && sweepinTime: # Gotta Sweep has not roamed around 5 times
		wander()
	elif wanders >= 5:
		go_home()
	
	for i in npcList: # shift other npcs
		if i.get("velocity") != null: # check that velocity exists
			var setVelocity = Vector3(velocity.x,i.velocity.y,velocity.z)
			# set to position then move
			if i is CharacterBody3D:
				var collide = i.move_and_collide(velocity * delta,true)
				if collide:
					setVelocity = setVelocity.slide(collide.get_normal()).normalized()*setVelocity.length()
			
			if i is Player:
				if !i.boots:
					i.velocity = setVelocity + (0.3 * i.velocity)
					i.sweeping = true
					i.failSafe = 1.0
			else:
				i.velocity = setVelocity + (0.1 * i.velocity)
			if i.get("navSkipSafe") != null:
				i.navSkipSafe = true
	
	super(delta)



func _on_area_3d_body_entered(body):
	if body == self: return
	sounds.stream = audSweep
	sounds.play()
	npcList.append(body)
	if body is Player:
		body.sweeping = true

func _on_area_3d_body_exited(body):
	if npcList.has(body):
		npcList.erase(body) # remove npc (if they're on the list)
	if body is Player:
		body.sweeping = false
