extends Area3D

@export var goTarget : Node3D = null
@export var fleeTarget : Node3D = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _exit_tree():
	body_entered.disconnect(_on_body_entered)
	body_exited.disconnect(_on_body_exited)

func _on_body_entered(_body):
	if is_instance_valid(Global.crafters):
		Global.crafters.give_location(goTarget.global_position,false)

func _on_body_exited(_body):
	if is_instance_valid(Global.crafters):
		Global.crafters.give_location(fleeTarget.global_position,true)
