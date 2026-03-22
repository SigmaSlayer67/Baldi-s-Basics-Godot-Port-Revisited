# ATTENTION: Script done! (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
extends Area3D

@export var go_target : Node3D = null
@export var flee_target : Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _exit_tree() -> void:
	body_entered.disconnect(_on_body_entered)
	body_exited.disconnect(_on_body_exited)

func _on_body_entered(_body : Node3D) -> void:
	if is_instance_valid(Global.crafters):
		Global.crafters.give_location(go_target.global_position,false)

func _on_body_exited(_body : Node3D) -> void:
	if is_instance_valid(Global.crafters):
		Global.crafters.give_location(flee_target.global_position,true)
