extends Node3D


func activate() -> void:
	lower()

func lower() -> void:
	position.y = -10.0

func raise() -> void:
	position.y = 0.0

func escape_activate() -> void: # called in math minigame (has to be in escape group)
	raise()


func _on_near_trigger_body_entered(_body : Node3D) -> void:
	if Global.escapesReached < 3 && Global.escapeMode:
		lower()
		Global.exit_reached()
		$Switch.play()
		# alert baldi
		if is_instance_valid(Global.baldi):
			Global.baldi.hear(global_position,8)
