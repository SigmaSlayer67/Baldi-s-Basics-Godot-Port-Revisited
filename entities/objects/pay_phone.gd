# ATTENTION: Script done! (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
extends Area3D


func use_quarter(_player : Player) -> void:
	if is_instance_valid(Global.baldi):
		Global.baldi.activate_anti_hearing(30.0) # anti hearing for 30 seconds
	$Audio.stop()
	$Audio.play()
