extends Character
# ATTENTION: Script done! (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
class_name Principal

@export var active : bool = false

var seeRuleBreak : bool = false
var bullySeen : bool = false
var coolDown : float = 0.0
var timeSeenRuleBreak : float = 0.0
var angry : bool = false
var inOffice : bool = false
var detentions : int = 0
var lockTimes : Array[int] = [15,30,45,60,99]

var audTimes : Array[AudioStream] = [
preload("res://audio/Characters/Principal/Times/PRI_15Sec.wav"),
preload("res://audio/Characters/Principal/Times/PRI_30Sec.wav"),
preload("res://audio/Characters/Principal/Times/PRI_45Sec.wav"),
preload("res://audio/Characters/Principal/Times/PRI_60Sec.wav"),
preload("res://audio/Characters/Principal/Times/PRI_99Sec.wav"),
]

var audScolds : Array[AudioStream]= [
preload("res://audio/Characters/Principal/Scolds/PRI_KnowBetter.wav"),
preload("res://audio/Characters/Principal/Scolds/PRI_WhenLearn.wav"),
preload("res://audio/Characters/Principal/Scolds/PRI_YourParents.wav"),
]

var audDetention : AudioStream = preload("res://audio/Characters/Principal/PRI_DetentionForYou.wav")
var audNoDrinking : AudioStream = preload("res://audio/Characters/Principal/RuleBroke/PRI_NoDrinking.wav")
var audNoBullying : AudioStream = preload("res://audio/Characters/Principal/RuleBroke/PRI_NoBullying.wav")
var audNoFaculty : AudioStream = preload("res://audio/Characters/Principal/RuleBroke/PRI_NoFaculty.wav")
var audNoLockers : AudioStream = preload("res://audio/Characters/Principal/RuleBroke/Unused/PRI_NoLockers.wav")
var audNoRunning : AudioStream = preload("res://audio/Characters/Principal/RuleBroke/PRI_NoRunning.wav")
var audNoStabbing : AudioStream = preload("res://audio/Characters/Principal/RuleBroke/Unused/PRI_NoStabbing.wav")
var audNoEscaping : AudioStream = preload("res://audio/Characters/Principal/RuleBroke/PRI_NoEscaping.wav")
var audWhistle : AudioStream = preload("res://audio/Characters/Principal/PRI_Whistle.wav")
# Unused variable, always comment these when you find that a variable is not used
# in any script or any other form, you can determine if a variable or function is unused
# by searching the exact name of it on "Project" > "Find in files..." or by pressing
# Cntrl + Shift + F as a shortcut, if you only want to search in this script only, press F3
# or press in the script editor button "Search" > "Find"
#var audDelay

var aim := Vector3.ZERO
var audioQueue : Array[AudioStream] = []
@onready var playerChecker : RayCast3D = $PlayerChecker
var canSeePlayer : bool = false
@onready var sounds : AudioStreamPlayer3D = $Sounds

@onready var principalOfficeLocation : Vector3 = global_position

func _ready() -> void:
	super()
	set_physics_process(active)
	visible = active

func activate() -> void:
	active = true
	set_physics_process(active)
	show()

#I don't like the idea of game logic being tied to frame rate, process should be used for animation and audio related events
func _physics_process(delta : float) -> void: 
	if seeRuleBreak:
		timeSeenRuleBreak += delta
		if timeSeenRuleBreak >= 0.5 && !angry:
			angry = true
			seeRuleBreak = false
			timeSeenRuleBreak = 0.0
			correct_player()
	else:
		timeSeenRuleBreak = 0.0
	coolDown = move_toward(coolDown,0.0,delta)
	
	
	# targeting
	# set player raycast
	if Global.player:
		playerChecker.target_position = Global.player.global_position - global_position
		# check that the cast wasn't interupted
		playerChecker.force_raycast_update()
		canSeePlayer = !playerChecker.is_colliding()
	
	if !angry:
		aim = global_position.direction_to(Global.player.global_position)
		if canSeePlayer && Global.player.guilt > 0.0 && !inOffice && !angry:
			seeRuleBreak = true
		else:
			seeRuleBreak = false
			
			if get_real_velocity().length() <= 1.0 && coolDown <= 0.0:
				wander()
		# bully logic
		if Global.bully:
			playerChecker.target_position = Global.bully.global_position - global_position
			playerChecker.force_raycast_update()
			if !playerChecker.is_colliding() && Global.bully.guilt > 0.0 && !inOffice && !angry:
				target_bully()

	else:
		navAgent.target_position = Global.player.global_position
	
	$PlayerCollider/CollisionShape3D.disabled = !$PlayerCollider/CollisionShape3D.disabled
	super(delta)
	velocity.y = 0.0
	

func wander() -> void:
	navAgent.target_position = Global.get_wander_point()# set random target based on targets
	coolDown = 1.0
	if randf_range(0.0,10.0) <= 1.0 && !sounds.playing:
		sounds.stream = audWhistle
		sounds.play()

func queue_audio(audio : AudioStream = null) -> void:
	audioQueue.append(audio)
	if !sounds.playing:
		sounds.stream = audioQueue[0]
		sounds.play()
		audioQueue.pop_front()

func correct_player() -> void:
	sounds.stop()
	audioQueue.clear()
	# get player rule break
	match(Global.player.guiltType):
		&"escape": # escaping detention
			queue_audio(audNoEscaping)
		&"drink": # bsoda
			queue_audio(audNoDrinking)
		&"faculty": # faculty 
			queue_audio(audNoFaculty)
		_: # default
			queue_audio(audNoRunning)

## Catching player
func _on_player_collider_body_entered(body : Node3D) -> void:
	if body is Player && angry && !inOffice:
		inOffice = true
		global_position = principalOfficeLocation+Vector3(0.0,0.0,-10.0)
		body.global_position = principalOfficeLocation
		body.look_at(Vector3(global_position.x,body.global_position.y,global_position.z),body.up_direction)
		body.detentionTimer = lockTimes[detentions]
		body.guilt = 0.0 # reset guilt
		body.jumpRope = false
		navAgent.target_position = global_position
		# Idk why the check is for baldi to be visible instead of just the instance being valid but i digress
		if Global.baldi.visible:
			Global.baldi.hear(global_position,8)
		coolDown = 5.0
		angry = false
		for i : Node in get_tree().get_nodes_in_group(&"principal_lock"):
			if i is Door:
				i.lockTime = lockTimes[detentions]
				i.doorLocked = true
		await get_tree().create_timer(0.250,false).timeout
		queue_audio(audTimes[detentions])
		queue_audio(audDetention)
		queue_audio(audScolds[randi_range(0,audScolds.size()-1)])
		detentions = min(detentions+1,4)


func _on_sounds_finished() -> void: # queue next audio
	if audioQueue.size() > 0:
		sounds.stream = audioQueue[0]
		sounds.play()
		audioQueue.pop_front()

func target_bully() -> void:
	if !bullySeen:
		navAgent.target_position = Global.bully.global_position
		queue_audio(audNoBullying)
		bullySeen = true
