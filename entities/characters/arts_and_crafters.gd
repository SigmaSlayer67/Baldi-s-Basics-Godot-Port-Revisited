extends Character
class_name Crafters

@export var active : bool = false

@export var audCrafterLoop : AudioStream = preload("res://audio/Characters/ArtsAndCrafters/CFT_Loop.wav")

@export var angrySprite : Texture2D = preload("res://graphics/Characters/ArtsAndCrafters/Crafters_Ohno.png")

@export var noteBookAnger : int = 7

var angry : bool = false
var gettingAngry : bool = false
var anger : float = 0.0
var forceShowTime : float = 0.0

@onready var sounds : AudioStreamPlayer3D = $Sounds
@onready var sprite : Sprite3D = $ArtsAndCrafters
@onready var playerChecker : RayCast3D = $PlayerChecker
@onready var visibilityChecker : VisibleOnScreenNotifier3D = $VisibilityChecker


func _ready() -> void:
	Global.crafters = self
	super()
	set_physics_process(active)
	visible = active

func activate() -> void:
	active = true
	set_physics_process(active)
	show()

func _process(delta : float) -> void:
	forceShowTime = move_toward(forceShowTime,0.0,delta)
	if gettingAngry: # if arts is getting angry
		anger += delta # Increase anger
		if anger >= 1.0 && !angry: # If anger is greater then 1 and arts isn't angry
			angry = true # Get angry
			sounds.play() # scream
			sprite.texture = angrySprite
	# if anger is greater then 0, decrease
	elif anger > 0.0: 
		anger = move_toward(anger,0.0,delta)

func _physics_process(delta : float) -> void:
	if !angry: # if not angry
		if is_instance_valid(Global.player):
			if (global_position.distance_to(navAgent.get_final_position()) <= 20.0 && global_position.distance_to(Global.player.global_position) >= 60) || forceShowTime > 0.0: # if close to the player and force showtime is less then 0
				visible = true # show
			else:
				visible = false # hide
	else:
		speed += 60.0 * delta # increase the speed
		navAgent.target_position = Global.player.global_position
	
	if Global.noteBooks >= noteBookAnger: # If the player has more then the note book count 
		playerChecker.target_position = (Global.player.global_position - global_position).slide(Vector3.UP)
		playerChecker.force_raycast_update()
		if !playerChecker.is_colliding() && visibilityChecker.is_on_screen() && visible: # if Arts is visible, and active and sees player
			gettingAngry = true # start getting angry
		else:
			gettingAngry = false # stop being angry
	super(delta)

func give_location(location : Vector3, flee : bool) -> void:
	if !angry && active:
		navAgent.target_position = location
		playerChecker.target_position = (Global.player.global_position - global_position).slide(Vector3.UP)
		playerChecker.force_raycast_update()
		if flee && !playerChecker.is_colliding(): # show if fleeing and line of sight isn't broken
			forceShowTime = 3.0 # Make arts appear in 3 seconds


# play full whoosh sound if rotating
func _on_sounds_finished() -> void:
	sounds.stream = audCrafterLoop
	sounds.play()



func _on_player_collider_body_entered(body : Node3D) -> void:
	if angry:
		body.global_position = Vector3(0.0,body.global_position.y,75.0) # Teleport the player
		if is_instance_valid(Global.baldi):
			Global.baldi.global_position = Vector3(0.0, Global.baldi.global_position.y, 120.0) # Teleport Baldi
			# Make the player look at baldi
			body.look_at(Vector3(Global.baldi.global_position.x,body.global_position.y,Global.baldi.global_position.z),body.up_direction)
		
		queue_free() # despawn
