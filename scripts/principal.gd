extends Character
class_name Principal

@export var active = false

var seeRuleBreak = false
var bullySeen = false
var coolDown = 0.0
var timeSeenRuleBreak = 0.0
var angry = false
var inOffice = false
var detentions = 0
var lockTimes = [15,30,45,60,99]

var audTimes = [
preload("res://audio/Characters/Principal/Times/PRI_15Sec.wav"),
preload("res://audio/Characters/Principal/Times/PRI_30Sec.wav"),
preload("res://audio/Characters/Principal/Times/PRI_45Sec.wav"),
preload("res://audio/Characters/Principal/Times/PRI_60Sec.wav"),
preload("res://audio/Characters/Principal/Times/PRI_99Sec.wav"),
]

var audScolds = [
preload("res://audio/Characters/Principal/Scolds/PRI_KnowBetter.wav"),
preload("res://audio/Characters/Principal/Scolds/PRI_WhenLearn.wav"),
preload("res://audio/Characters/Principal/Scolds/PRI_YourParents.wav"),
]

var audDetention = preload("res://audio/Characters/Principal/PRI_DetentionForYou.wav")
var audNoDrinking = preload("res://audio/Characters/Principal/RuleBroke/PRI_NoDrinking.wav")
var audNoBullying = preload("res://audio/Characters/Principal/RuleBroke/PRI_NoBullying.wav")
var audNoFaculty = preload("res://audio/Characters/Principal/RuleBroke/PRI_NoFaculty.wav")
var audNoLockers = preload("res://audio/Characters/Principal/RuleBroke/Unused/PRI_NoLockers.wav")
var audNoRunning = preload("res://audio/Characters/Principal/RuleBroke/PRI_NoRunning.wav")
var audNoStabbing = preload("res://audio/Characters/Principal/RuleBroke/Unused/PRI_NoStabbing.wav")
var audNoEscaping = preload("res://audio/Characters/Principal/RuleBroke/PRI_NoEscaping.wav")
var audWhistle = preload("res://audio/Characters/Principal/PRI_Whistle.wav")
var audDelay

var aim = Vector3.ZERO
var audioQueue = []
@onready var playerChecker = $PlayerChecker
var canSeePlayer = false
@onready var sounds = $Sounds

@onready var principalOfficeLocation = global_position

func _ready():
	super()
	set_physics_process(active)
	visible = active

func activate():
	active = true
	set_physics_process(active)
	show()

func _physics_process(delta): #I don't like the idea of game logic being tied to frame rate, process should be used for animation and audio related events
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
		if canSeePlayer && Global.player.guilt > 0 && !inOffice && !angry:
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
	

func wander():
	navAgent.target_position = Global.get_wander_point()# set random target based on targets
	coolDown = 1.0
	if randf_range(0.0,10.0) <= 1.0 && !sounds.playing:
		sounds.stream = audWhistle
		sounds.play()

func queue_audio(audio:AudioStream = null):
	audioQueue.append(audio)
	if !sounds.playing:
		sounds.stream = audioQueue[0]
		sounds.play()
		audioQueue.pop_front()

func correct_player():
	sounds.stop()
	audioQueue.clear()
	# get player rule break
	match(Global.player.guiltType):
		"escape": # escaping detention
			queue_audio(audNoEscaping)
		"drink": # bsoda
			queue_audio(audNoDrinking)
		"faculty": # faculty 
			queue_audio(audNoFaculty)
		_: # default
			queue_audio(audNoRunning)

## Catching player
func _on_player_collider_body_entered(body):
	if body is Player && angry && !inOffice:
		inOffice = true
		global_position = principalOfficeLocation+Vector3(0,0,-10)
		body.global_position = principalOfficeLocation
		body.look_at(Vector3(global_position.x,body.global_position.y,global_position.z),body.up_direction)
		body.detentionTimer = lockTimes[detentions]
		body.guilt = 0.0 # reset guilt
		body.jumpRope = false
		navAgent.target_position = global_position
		if Global.baldi.visible:
			Global.baldi.hear(global_position,8)
		coolDown = 5.0
		angry = false
		for i in get_tree().get_nodes_in_group("principal_lock"):
			if i is Door:
				i.lockTime = lockTimes[detentions]
				i.doorLocked = true
		await get_tree().create_timer(0.250,false).timeout
		queue_audio(audTimes[detentions])
		queue_audio(audDetention)
		queue_audio(audScolds[randi_range(0,audScolds.size()-1)])
		detentions = min(detentions+1,4)
	
	


func _on_sounds_finished():# queue next audio
	if audioQueue.size() > 0:
		sounds.stream = audioQueue[0]
		sounds.play()
		audioQueue.pop_front()

func target_bully():
	if !bullySeen:
		navAgent.target_position = Global.bully.global_position
		queue_audio(audNoBullying)
		bullySeen = true
