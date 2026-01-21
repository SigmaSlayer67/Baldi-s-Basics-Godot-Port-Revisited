extends Character
class_name Baldi

@export var active : bool = false

var baseTime : float = 3.0
var timeToMove : float = 0.0

var baldiWait : float = 3.0

var baldiSpeedScale : float = 0.65

var moveFrames : float = 0.0

var currentPriority : int = 0

var antiHearing : bool = false
var antiHearingTime : float = 0.0
var vibrationDistance : float = 50.0

var baldiAnger : float = 0.0
var baldiTempAnger : float = 0.0
var angerRate : float = 0.01
var angerRateRatio : float = 0.00025
var angerFrequency : float = 1.0
var timeToAnger : float = 0.0

var wanderTarget := Vector3.ZERO
var previous := Vector3.ZERO

var coolDown : float = 0.0

var rumble : bool = false

@onready var sfxSlap : AudioStreamPlayer3D = $Slap
@onready var playerChecker : RayCast3D = $PlayerChecker

func _ready() -> void:
	super()
	Global.baldi = self
	wander()
	set_physics_process(active)
	visible = active

func activate() -> void:
	active = true
	show()
	set_physics_process(active)
	playerChecker.target_position = Global.player.global_position - global_position
	playerChecker.force_raycast_update()
	

func _process(_delta : float) -> void:
	$Baldi.speed_scale = max(1.0,speed/60.0)

func _physics_process(delta : float) -> void:
	
	# cool downs
	if timeToMove > 0.0: # decrease if time to move is greater then 0
		timeToMove -= delta
	else:
		move() # move
	
	coolDown = max(0,coolDown-delta) # decrease cool down if above 0
	
	baldiTempAnger = move_toward(baldiTempAnger,0.0,0.02 * delta)
	
	
	# anti hearing
	if antiHearingTime > 0: # decrease anti hearing time, if below 0 then stop anti hearing
		antiHearingTime -= delta
	else:
		antiHearing = false
	
	# endless anger mechanics
	if Global.endless: # only applies to endless mode
		if timeToAnger > 0: # decrease time to anger
			timeToAnger -= delta
		else:
			timeToAnger = angerFrequency
			get_angry(angerRate) # get angry based on anger rate
			angerRate += angerRateRatio # increase anger for next anger call
	
	# moving
	if moveFrames > 0:
		speed = 75.0
		moveFrames -= delta*60.0
	else:
		speed = 0.0
	
	# targeting
	# set player raycast
	if Global.player:
		playerChecker.target_position = Global.player.global_position - global_position
		# check that the cast wasn't interupted
		if !playerChecker.is_colliding():
			set_target_node(Global.player)
	
	super(delta) # call parent movement class


func wander() -> void:
	navAgent.target_position = Global.get_wander_point()# set random target based on targets
	coolDown = 1.0 # set cool down
	currentPriority = 0 # reset priority

func set_target_node(object : Node3D) -> void:
	navAgent.target_position = object.global_position
	coolDown = 1.0 # set cool down
	currentPriority = 0 # reset priority


func move() -> void:
	if global_position.is_equal_approx(previous) && coolDown <= 0:
		wander()
	moveFrames = 10.0
	timeToMove = baldiWait - baldiTempAnger
	previous = global_position
	sfxSlap.play()
	$Baldi.stop()
	$Baldi.play("slap")
	# rumble
	if Global.rumble:
		var distance : float = global_position.distance_to(Global.player.global_position)
		if distance <= vibrationDistance:
			Input.start_joy_vibration(0, 0.5, 1.0-(distance/vibrationDistance), 0.15)

func get_angry(setAnger : float) -> void:
	baldiAnger = max(0.5,baldiAnger+setAnger) # increase anger but cap baldi's lower anger to 0.5
	baldiWait = -3.0 * baldiAnger / (baldiAnger + 2.0 / baldiSpeedScale) + 3.0 # keeps baldi from going nuts I think, i dunno, comment it out see what happens lmao

func get_temp_anger(tempSet : float) -> void:
	baldiTempAnger += tempSet # idk why this is a function but hey you can always add some checks this way

func hear(soundLocation := Vector3.ZERO, priority : int = 0, playReaction : bool = true) -> void:
	if !antiHearing:
		if priority >= currentPriority:
			var oldTarget : Vector3 = navAgent.target_position # used to determine if the point is reachable
			navAgent.target_position = soundLocation # set new location
			if navAgent.get_final_position().slide(Vector3.UP).distance_to(navAgent.target_position.slide(Vector3.UP)) > 1.0: # if unreachable, set target to old target (use a distance verify because positions in the air don't play nice with is_target_reachable)
				navAgent.target_position = oldTarget
				# play a confused reaction
				if active && playReaction:
					Global.player.bali_react("Confused")
			else: # else set the new priority
				currentPriority = priority
				# play a notice reaction
				if active && playReaction:
					Global.player.bali_react("Notice")
		# play a confused reaction if the current priority is more important
		elif active:
			Global.player.bali_react("Confused")

func activate_anti_hearing(time : float) -> void:
	wander()
	antiHearing = true
	antiHearingTime = time

func _on_player_collider_body_entered(body : Node3D) -> void:
	if playerChecker.is_colliding(): return
	if body is Player && visible:
		if body.has_method("game_over"):
			body.game_over()
