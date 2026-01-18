extends Node3D


func activate():
	lower()

func lower():
	position.y = -10.0

func raise():
	position.y = 0.0

func escape_activate(): # called in math minigame (has to be in escape group)
	raise()


func _on_near_trigger_body_entered(_body):
	if Global.escapesReached < 3 && Global.escapeMode:
		lower()
		Global.exit_reached()
		$Switch.play()
		# alert baldi
		if is_instance_valid(Global.baldi):
			Global.baldi.hear(global_position,8)
