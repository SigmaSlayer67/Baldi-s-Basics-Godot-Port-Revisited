# ATTENTION: Script donenot  (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
extends Character
class_name Principal

@export var active : bool = false

var see_rule_break : bool = false
var bully_seen : bool = false
var cool_down : float = 0.0
var time_seen_rule_break : float = 0.0
var angry : bool = false
var in_office : bool = false
var detentions : int = 0
var lock_times : Array[int] = [15,30,45,60,99]

var aud_times : Array[AudioStream] = [
preload("res://audio/Characters/Principal/Times/PRI_15Sec.wav"),
preload("res://audio/Characters/Principal/Times/PRI_30Sec.wav"),
preload("res://audio/Characters/Principal/Times/PRI_45Sec.wav"),
preload("res://audio/Characters/Principal/Times/PRI_60Sec.wav"),
preload("res://audio/Characters/Principal/Times/PRI_99Sec.wav"),
]

var aud_scolds : Array[AudioStream]= [
preload("res://audio/Characters/Principal/Scolds/PRI_KnowBetter.wav"),
preload("res://audio/Characters/Principal/Scolds/PRI_WhenLearn.wav"),
preload("res://audio/Characters/Principal/Scolds/PRI_YourParents.wav"),
]

var aud_detention : AudioStream = preload("res://audio/Characters/Principal/PRI_DetentionForYou.wav")
var aud_no_drinking : AudioStream = preload("res://audio/Characters/Principal/RuleBroke/PRI_NoDrinking.wav")
var aud_no_bullying : AudioStream = preload("res://audio/Characters/Principal/RuleBroke/PRI_NoBullying.wav")
var aud_no_faculty : AudioStream = preload("res://audio/Characters/Principal/RuleBroke/PRI_NoFaculty.wav")
var aud_no_lockers : AudioStream = preload("res://audio/Characters/Principal/RuleBroke/Unused/PRI_NoLockers.wav")
var aud_no_running : AudioStream = preload("res://audio/Characters/Principal/RuleBroke/PRI_NoRunning.wav")
var aud_no_stabbing : AudioStream = preload("res://audio/Characters/Principal/RuleBroke/Unused/PRI_NoStabbing.wav")
var aud_no_escaping : AudioStream = preload("res://audio/Characters/Principal/RuleBroke/PRI_NoEscaping.wav")
var aud_whistle : AudioStream = preload("res://audio/Characters/Principal/PRI_Whistle.wav")
# Unused variable, always comment these when you find that a variable is not used
# in any script or any other form, you can determine if a variable or function is unused
# by searching the exact name of it on "Project" > "Find in files..." or by pressing
# Cntrl + Shift + F as a shortcut, if you only want to search in this script only, press F3
# or press in the script editor button "Search" > "Find"
#var audDelay

var aim := Vector3.ZERO
var audio_queue : Array[AudioStream] = []
@onready var player_checker : RayCast3D = $PlayerChecker
var can_see_player : bool = false
@onready var sounds : AudioStreamPlayer3D = $Sounds

@onready var principal_office_location : Vector3 = global_position

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
	if see_rule_break:
		time_seen_rule_break += delta
		if time_seen_rule_break >= 0.5 and not angry:
			angry = true
			see_rule_break = false
			time_seen_rule_break = 0.0
			correct_player()
	else:
		time_seen_rule_break = 0.0
	cool_down = move_toward(cool_down,0.0,delta)
	
	
	# targeting
	# set player raycast
	if Global.player:
		player_checker.target_position = Global.player.global_position - global_position
		# check that the cast wasn't interupted
		player_checker.force_raycast_update()
		can_see_player = not player_checker.is_colliding()
	
	if not angry:
		aim = global_position.direction_to(Global.player.global_position)
		if can_see_player and Global.player.guilt > 0.0 and not in_office and not angry:
			see_rule_break = true
		else:
			see_rule_break = false
			
			if get_real_velocity().length() <= 1.0 and cool_down <= 0.0:
				wander()
		# bully logic
		if Global.bully:
			player_checker.target_position = Global.bully.global_position - global_position
			player_checker.force_raycast_update()
			if not player_checker.is_colliding() and Global.bully.guilt > 0.0 and not in_office and not angry:
				target_bully()

	else:
		navAgent.target_position = Global.player.global_position
	
	$PlayerCollider/CollisionShape3D.disabled = not $PlayerCollider/CollisionShape3D.disabled
	super(delta)
	velocity.y = 0.0
	

func wander() -> void:
	navAgent.target_position = Global.get_wander_point()# set random target based on targets
	cool_down = 1.0
	if randf_range(0.0,10.0) <= 1.0 and not sounds.playing:
		sounds.stream = aud_whistle
		sounds.play()

func queue_audio(audio : AudioStream = null) -> void:
	audio_queue.append(audio)
	if not sounds.playing:
		sounds.stream = audio_queue[0]
		sounds.play()
		audio_queue.pop_front()

func correct_player() -> void:
	sounds.stop()
	audio_queue.clear()
	# get player rule break
	match(Global.player.guilt_type):
		"escape": # escaping detention
			queue_audio(aud_no_escaping)
		"drink": # bsoda
			queue_audio(aud_no_drinking)
		"faculty": # faculty 
			queue_audio(aud_no_faculty)
		_: # default
			queue_audio(aud_no_running)

## Catching player
func _on_player_collider_body_entered(body : Node3D) -> void:
	if body is Player and angry and not in_office:
		in_office = true
		global_position = principal_office_location+Vector3(0.0,0.0,-10.0)
		body.global_position = principal_office_location
		body.look_at(Vector3(global_position.x,body.global_position.y,global_position.z),body.up_direction)
		body.detentionTimer = lock_times[detentions]
		body.guilt = 0.0 # reset guilt
		body.jumpRope = false
		navAgent.target_position = global_position
		# Idk why the check is for baldi to be visible instead of just the instance being valid but i digress
		if Global.baldi.visible:
			Global.baldi.hear(global_position,8)
		cool_down = 5.0
		angry = false
		for i : Node in get_tree().get_nodes_in_group("principal_lock"):
			if i is Door:
				i.lockTime = lock_times[detentions]
				i.doorLocked = true
		await get_tree().create_timer(0.250,false).timeout
		queue_audio(aud_times[detentions])
		queue_audio(aud_detention)
		queue_audio(aud_scolds[randi_range(0,aud_scolds.size()-1)])
		detentions = min(detentions+1,4)


func _on_sounds_finished() -> void: # queue next audio
	if audio_queue.size() > 0:
		sounds.stream = audio_queue[0]
		sounds.play()
		audio_queue.pop_front()

func target_bully() -> void:
	if not bully_seen:
		navAgent.target_position = Global.bully.global_position
		queue_audio(aud_no_bullying)
		bully_seen = true
