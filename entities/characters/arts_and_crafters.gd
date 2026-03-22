# ATTENTION: Script done! (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
class_name Crafters
extends Character

@export var active : bool = false

@export var aud_crafter_loop : AudioStream = preload(
	"res://audio/Characters/ArtsAndCrafters/CFT_Loop.wav"
)

@export var angry_sprite : Texture2D = preload(
	"res://graphics/Characters/ArtsAndCrafters/Crafters_Ohno.png"
)

@export var note_book_anger : int = 7

var angry : bool = false
var getting_angry : bool = false
var anger : float = 0.0
var force_show_time : float = 0.0

@onready var sounds : AudioStreamPlayer3D = $Sounds
@onready var sprite : Sprite3D = $ArtsAndCrafters
@onready var player_checker : RayCast3D = $PlayerChecker
@onready var visibility_checker : VisibleOnScreenNotifier3D = $VisibilityChecker


func _ready() -> void:
	Global.crafters = self
	super()
	set_physics_process(active)
	visible = active


func _process(delta : float) -> void:
	force_show_time = move_toward(force_show_time, 0.0, delta)
	if getting_angry: # if arts is getting angry
		anger += delta # Increase anger
		# If anger is greater then 1 and arts isn't angry
		if anger >= 1.0 and not angry:
			angry = true # Get angry
			sounds.play() # scream
			sprite.texture = angry_sprite
	# if anger is greater then 0, decrease
	elif anger > 0.0: 
		anger = move_toward(anger, 0.0, delta)


func _physics_process(delta : float) -> void:
	if not angry: # if not angry
		if is_instance_valid(Global.player):
			# if close to the player and force showtime is less then 0
			if (global_position.distance_to(navAgent.get_final_position()) <= 20.0 \
					and global_position.distance_to(Global.player.global_position) >= 60.0) \
					or force_show_time > 0.0:
				visible = true # show
			else:
				visible = false # hide
	else:
		speed += 60.0 * delta # increase the speed
		navAgent.target_position = Global.player.global_position
	
	# If the player has more then the note book count 
	if Global.noteBooks >= note_book_anger:
		player_checker.target_position = (Global.player.global_position - global_position).slide(Vector3.UP)
		player_checker.force_raycast_update()
		# if Arts is visible, and active and sees player
		if not player_checker.is_colliding() and visibility_checker.is_on_screen() and visible:
			getting_angry = true # start getting angry
		else:
			getting_angry = false # stop being angry
	super(delta)


# play full whoosh sound if rotating
func _on_sounds_finished() -> void:
	sounds.stream = aud_crafter_loop
	sounds.play()


func _on_player_collider_body_entered(body : Node3D) -> void:
	if angry:
		body.global_position = Vector3(0.0, body.global_position.y, 75.0) # Teleport the player
		if is_instance_valid(Global.baldi):
			Global.baldi.global_position = Vector3(0.0, Global.baldi.global_position.y, 120.0) # Teleport Baldi
			# Make the player look at baldi
			body.look_at(Vector3(Global.baldi.global_position.x, body.global_position.y, Global.baldi.global_position.z), body.up_direction)
		
		call_deferred(&"queue_free") # despawn


func activate() -> void:
	active = true
	set_physics_process(active)
	show()


func give_location(location : Vector3, flee : bool) -> void:
	if not angry and active:
		navAgent.target_position = location
		player_checker.target_position = (Global.player.global_position - global_position).slide(Vector3.UP)
		player_checker.force_raycast_update()
		# show if fleeing and line of sight isn't broken
		if flee and not player_checker.is_colliding():
			force_show_time = 3.0 # Make arts appear in 3 seconds
