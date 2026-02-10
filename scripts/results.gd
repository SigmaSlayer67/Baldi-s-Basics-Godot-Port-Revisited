# ATTENTION: Script done! (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
extends Control


func _on_timer_timeout() -> void:
	get_tree().quit()
