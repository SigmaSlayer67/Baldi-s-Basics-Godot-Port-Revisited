# ATTENTION: Script donenot  (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
@tool
extends Area3D
class_name Door

@onready var barrier : CollisionShape3D = $Door/CollisionShape3D
@onready var navigation_link : NavigationRegion3D = get_node_or_null("NavigationLink")
@export var audio_door_open : AudioStream = preload("res://audio/SFX/Doors/door_open.wav")
@export var audio_door_close : AudioStream = preload("res://audio/SFX/Doors/door_close.wav")

@export var back_side_darker : bool = false

var silent_opens : int = 0
var open_time : float = 0.0
var lock_time : float = 0.0
@onready var my_audio : AudioStreamPlayer3D = $Door/Sound
var door_open : bool = false
var door_locked : bool = false
@onready var door_texture : Sprite3D = $DoorTexture
@export var set_door_frame : int = 112:
	set(value):
		set_door_frame = value
		if has_node("DoorTexture"):
			get_node("DoorTexture").frame = value
			if has_node("DoorTexture/Duplicate"):
				get_node("DoorTexture/Duplicate").frame = value

@onready var default_door_frame : int = set_door_frame

var interacting_bodies : Array[Node3D] = []
@onready var door_collider : StaticBody3D = $Door

@export var lock_for_tutorial : bool = false

@export var door_nav_link_scale : float = 1.0

@export var double_door : bool = false

@export var exit_door : bool = false

func _ready() -> void:
	if not Engine.is_editor_hint():
		Global.note_books_updated.connect(note_book_check)
		$DoorTexture/Duplicate.modulate = Color.WHITE if not back_side_darker else Color(0.5,0.5,0.5)
		if is_instance_valid(navigation_link): # check that navigation link exists
			navigation_link.enabled = not lock_for_tutorial
#			navigation_link.scale.z = 1.0
#			navigation_link.position.y = door_nav_link_scale*10.0
	# just run the set_door_frame
	set_door_frame = set_door_frame
	

func _physics_process(delta : float) -> void:
	if not Engine.is_editor_hint():
		if lock_time > 0.0:
			lock_time = move_toward(lock_time,0.0,delta)
		elif door_locked:
			door_locked = false
		elif double_door and $DoorTexture/Lock.visible:
			$DoorTexture/Lock.hide()
			$DoorTexture/Duplicate/Lock.hide()
			navigation_link.enabled = true
			barrier.disabled = true
		
		
		open_time = move_toward(open_time,0.0,delta)
		
		if not interacting_bodies.is_empty():
			open_time = 2.0
		
		if open_time <= 0.0 and door_open:
			if not double_door: # only unlock for normal door
				barrier.disabled = false # turn on collision
			door_open = false # Set door open status to false
			door_texture.frame = defaultDoorFrame # set frame to closed frame
			if silent_opens <= 0:
				my_audio.stream = audio_door_close
				my_audio.play() # play door close sound
	else:
		$DoorTexture/Duplicate.modulate = Color.WHITE if not back_side_darker else Color(0.5,0.5,0.5)
#		if is_instance_valid(navigation_link): # check that navigation link exists
#			navigation_link.scale.z = 1.0
#			navigation_link.position.y = door_nav_link_scale*10.0
			


func interact(_object : Object) -> void:
	if double_door: return
	if not door_locked:
		if silent_opens <= 0 and is_instance_valid(Global.baldi) and not door_open and open_time <= 0.0: # alert baldi if the door isn't silent
			Global.baldi.hear(global_position,1)
		open_door()
		if silent_opens > 0 and not door_open and open_time <= 0.0:
			silent_opens -= 1 # decrease silent door counter

# opens the door
func open_door() -> void:
	if lock_time > 0.0: return
	if silent_opens <= 0 and not door_open:
		my_audio.stream = audio_door_open
		my_audio.play() # play door open sound if not silent and not already open
	barrier.call_deferred("set_disabled",true) # turn off collision
	door_open = true # Set the door open status to true
	door_texture.frame = defaultDoorFrame+1 # set frame to open frame
	open_time = 3.0 # Set the open time to 3 seconds
	

func _on_character_check_body_entered(body : Node3D) -> void:
	if not interacting_bodies.has(body):
		interacting_bodies.append(body)
	
	if lock_for_tutorial and Global.noteBooks < 2: # lock for notebooks
		if body is Player and has_node("BaldiGuide") and not exit_door: # only play audio if player
			if not get_node("BaldiGuide").is_playing():
				get_node("BaldiGuide").play()
	else:
		# npc collisions
		if (not door_locked or not double_door) and not exit_door:
			open_door()
		if body is Player and is_instance_valid(Global.baldi): # alert baldi
			if exit_door:
				# check for secret exit (all note books failed)
				if Global.secret:
					get_tree().call_deferred("change_scene_to_file","res://scenes/secret.tscn")
				else: # otherwise go to the normal ending
					get_tree().call_deferred("change_scene_to_file","res://scenes/results.tscn")
			else:
				Global.baldi.hear(global_position,1)

func _on_character_check_body_exited(body : Node3D) -> void:
	if interacting_bodies.has(body):
		interacting_bodies.erase(body)


func _on_door_texture_frame_changed() -> void:
	if door_texture not = null:
		$DoorTexture/Duplicate.frame = door_texture.frame


func _on_door_texture_texture_changed() -> void:
	if door_texture not = null:
		$DoorTexture/Duplicate.texture = door_texture.texture


func _on_door_texture_visibility_changed() -> void:
	if door_texture not = null:
		$DoorTexture/Duplicate.visible = door_texture.visible

func note_book_check() -> void:
	# remove solid wall if note books above 2
	if Global.noteBooks >= 2 and lock_for_tutorial:
		#door_collider.collision_layer = 0 # reset collision mask
		barrier.disabled = true # disable barrier
		if is_instance_valid(navigation_link): # check that navigation link exists
			navigation_link.enabled = true # enable nav mesh navigation

func lock_double_door() -> bool:
	if not double_door or lock_time > 0.0: return false
	$DoorTexture/Lock.show()
	$DoorTexture/Duplicate/Lock.show()
	lock_time = 15.0
	navigation_link.enabled = false
	open_time = 0.0 # close the door
	door_open = true
	barrier.disabled = false
	door_locked = true
	return true

func no_squee() -> bool:
	if double_door: return false
	silent_opens = 4
	return true
	
func use_key() -> bool:
	if double_door or not door_locked: return false
	door_locked = false
	return true
