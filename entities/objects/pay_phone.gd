extends Area3D

func use_quarter(_player : Player):
	if is_instance_valid(Global.baldi):
		Global.baldi.activate_anti_hearing(30.0) # anti hearing for 30 seconds
	$Audio.stop()
	$Audio.play()
