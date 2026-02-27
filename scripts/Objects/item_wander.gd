# ATTENTION: Script done! (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
@tool
extends Item


# skip first wander point because it's the start
func _ready() -> void:
	if not Engine.is_editor_hint():
		global_position = Global.get_wander_point(&"wander", 1, 15) + Vector3(0.0, 4.0, 0.0)
