# ATTENTION: Script done! (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
@tool
extends Area3D

var respawn_time : float = 0.0

@export_range(0,6)var note_book_index : int = 0:
	get:
		return note_book_index
	set(value):
		note_book_index = value
		if get_node_or_null("NoteBook") != null:
			get_node("NoteBook").frame = value

func interact(object : Object) -> void:
	if !visible:
		return
	var math : Node = Global.MathGame.instantiate()
	get_parent().add_child(math)
	get_tree().paused = true
	visible = false
	# give player stamina
	if object is Player:
		# this might be cheating as changes like these should be made on their own
		# separate branch after we finish the static typing one but i just wanted to make a
		# little change for more type safety that will be used for the future
		var player : Player = object as Player
		player.stamina = player.maxStamina
	# set respawn time for endless mode
	if Global.endless:
		respawn_time = 120.0

func _process(_delta : float) -> void:
	$NoteBook.position.y = sin(Engine.get_frames_drawn() * 0.017453292) / 2.0 + 1.0

func _physics_process(delta : float) -> void:
	# count down respawn time, if the time hits below 0 then respawn
	if respawn_time > 0.0:
		respawn_time -= delta
		# apear and play sound
		if respawn_time <= 0.0:
			visible = true
			$Respawn.play()
