# ATTENTION: Script donenot  (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
class_name Character
extends CharacterBody3D

@onready var nav_agent : NavigationAgent3D = get_node_or_null("Nav")
var speed : float = 0.0
var nav_skip_safe : bool = false

func _ready() -> void:
	if nav_agent != null:
		speed = nav_agent.max_speed # set speed to nav agents max speed
		nav_agent.velocity_computed.connect(_on_nav_velocity_computed)

func _physics_process(delta : float) -> void:
	var test_col : KinematicCollision3D = move_and_collide(velocity*delta,true)
	if test_col:
		if test_col.get_collider() is Character:
			test_col.get_collider().shove(-test_col.get_normal()*delta)
		velocity = velocity.slide(test_col.get_normal())
	#move_and_collide(velocity*delta)
	move_and_slide()
	velocity = global_position.direction_to(nav_agent.get_next_path_position())*speed
	if nav_agent != null:
		nav_agent.max_speed = speed
		nav_agent.velocity = velocity

func _on_nav_velocity_computed(safe_velocity : Vector3) -> void:
	if not nav_skip_safe and nav_agent.avoidance_enabled:
		velocity = safe_velocity
		nav_skip_safe = false

func shove(shove_velocity : Vector3) -> void:
	move_and_collide(shove_velocity)
