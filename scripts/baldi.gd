# ATTENTION: Script donenot  (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
extends Character
class_name Baldi

@export var active : bool = false

var base_time : float = 3.0
var time_to_move : float = 0.0

var baldi_wait : float = 3.0

var baldi_speed_scale : float = 0.65

var move_frames : float = 0.0

var current_priority : int = 0

var anti_hearing : bool = false
var anti_hearing_time : float = 0.0
var vibration_distance : float = 50.0

var baldi_anger : float = 0.0
var baldi_temp_anger : float = 0.0
var anger_rate : float = 0.01
var anger_rate_ratio : float = 0.00025
var anger_frequency : float = 1.0
var time_to_anger : float = 0.0

var wander_target := Vector3.ZERO
var previous := Vector3.ZERO

var cool_down : float = 0.0

var rumble : bool = false

@onready var sfx_slap : AudioStreamPlayer3D = $Slap
@onready var player_checker : RayCast3D = $PlayerChecker

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
	player_checker.target_position = Global.player.global_position - global_position
	player_checker.force_raycast_update()
	

func _process(_delta : float) -> void:
	$Baldi.speed_scale = max(1.0,speed/60.0)

func _physics_process(delta : float) -> void:
	
	# cool downs
	if time_to_move > 0.0: # decrease if time to move is greater then 0
		time_to_move -= delta
	else:
		move() # move
	
	cool_down = max(0.0,cool_down-delta) # decrease cool down if above 0
	
	baldi_temp_anger = move_toward(baldi_temp_anger,0.0,0.02 * delta)
	
	
	# anti hearing
	if anti_hearing_time > 0.0: # decrease anti hearing time, if below 0 then stop anti hearing
		anti_hearing_time -= delta
	else:
		anti_hearing = false
	
	# endless anger mechanics
	if Global.endless: # only applies to endless mode
		if time_to_anger > 0.0: # decrease time to anger
			time_to_anger -= delta
		else:
			time_to_anger = anger_frequency
			get_angry(anger_rate) # get angry based on anger rate
			anger_rate += anger_rate_ratio # increase anger for next anger call
	
	# moving
	if move_frames > 0.0:
		speed = 75.0
		move_frames -= delta*60.0
	else:
		speed = 0.0
	
	# targeting
	# set player raycast
	if Global.player:
		player_checker.target_position = Global.player.global_position - global_position
		# check that the cast wasn't interupted
		if not player_checker.is_colliding():
			set_target_node(Global.player)
	
	super(delta) # call parent movement class


func wander() -> void:
	nav_agent.target_position = Global.get_wander_point()# set random target based on targets
	cool_down = 1.0 # set cool down
	current_priority = 0 # reset priority

func set_target_node(object : Node3D) -> void:
	nav_agent.target_position = object.global_position
	cool_down = 1.0 # set cool down
	current_priority = 0 # reset priority


func move() -> void:
	if global_position.is_equal_approx(previous) and cool_down <= 0.0:
		wander()
	move_frames = 10.0
	time_to_move = baldi_wait - baldi_temp_anger
	previous = global_position
	sfx_slap.play()
	$Baldi.stop()
	$Baldi.play("slap")
	# rumble
	if Global.rumble:
		var distance : float = global_position.distance_to(Global.player.global_position)
		if distance <= vibration_distance:
			Input.start_joy_vibration(0, 0.5, 1.0-(distance/vibration_distance), 0.15)

func get_angry(set_anger : float) -> void:
	baldi_anger = max(0.5,baldi_anger+set_anger) # increase anger but cap baldi's lower anger to 0.5
	baldi_wait = -3.0 * baldi_anger / (baldi_anger + 2.0 / baldi_speed_scale) + 3.0 # keeps baldi from going nuts I think, i dunno, comment it out see what happens lmao

func get_temp_anger(temp_set : float) -> void:
	baldi_temp_anger += temp_set # idk why this is a function but hey you can always add some checks this way

func hear(sound_location := Vector3.ZERO, priority : int = 0, play_reaction : bool = true) -> void:
	if not anti_hearing:
		if priority >= current_priority:
			var old_target : Vector3 = nav_agent.target_position # used to determine if the point is reachable
			nav_agent.target_position = sound_location # set new location
			if nav_agent.get_final_position().slide(Vector3.UP).distance_to(nav_agent.target_position.slide(Vector3.UP)) > 1.0: # if unreachable, set target to old target (use a distance verify because positions in the air don't play nice with is_target_reachable)
				nav_agent.target_position = old_target
				# play a confused reaction
				if active and play_reaction:
					Global.player.bali_react("Confused")
			else: # else set the new priority
				current_priority = priority
				# play a notice reaction
				if active and play_reaction:
					Global.player.bali_react("Notice")
		# play a confused reaction if the current priority is more important
		elif active:
			Global.player.bali_react("Confused")

func activate_anti_hearing(time : float) -> void:
	wander()
	anti_hearing = true
	anti_hearing_time = time

func _on_player_collider_body_entered(body : Node3D) -> void:
	if player_checker.is_colliding(): return
	if body is Player and visible:
		if body.has_method("game_over"):
			body.game_over()
