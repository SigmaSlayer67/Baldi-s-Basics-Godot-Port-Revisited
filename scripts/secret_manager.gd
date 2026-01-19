extends Node3D

func _process(_delta : float) -> void:
	# make baldi face the camera
	var camera = get_viewport().get_camera_3d()
	var baldi = $Badi/BaldiSprite
	baldi.look_at(baldi.global_position+camera.global_basis.z,Vector3.UP)

# when dialogue file finished close the game
func _on_recording_finished() -> void:
	get_tree().quit()

# run ending dialogue
func _on_ending_body_entered(_body : Node3D) -> void:
	if !$Filename2/Recording.is_playing():
		$Filename2/Recording.play()
