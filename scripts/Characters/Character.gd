class_name Character
extends CharacterBody3D

@onready var navAgent :NavigationAgent3D = get_node_or_null("Nav")
var speed = 0.0
var navSkipSafe = false

func _ready():
	if navAgent != null:
		speed = navAgent.max_speed # set speed to nav agents max speed
		navAgent.velocity_computed.connect(_on_nav_velocity_computed)

func _physics_process(delta):
	var testCol = move_and_collide(velocity*delta,true)
	if testCol:
		if testCol.get_collider() is Character:
			testCol.get_collider().shove(-testCol.get_normal()*delta)
		velocity = velocity.slide(testCol.get_normal())
	#move_and_collide(velocity*delta)
	move_and_slide()
	velocity = global_position.direction_to(navAgent.get_next_path_position())*speed
	if navAgent != null:
		navAgent.max_speed = speed
		navAgent.velocity = velocity

func _on_nav_velocity_computed(safe_velocity):
	if !navSkipSafe && navAgent.avoidance_enabled:
		velocity = safe_velocity
		navSkipSafe = false

func shove(shove_velocity):
	move_and_collide(shove_velocity)
