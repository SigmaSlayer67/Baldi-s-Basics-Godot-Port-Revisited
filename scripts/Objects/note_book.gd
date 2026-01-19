@tool
extends Area3D

var respawnTime : float = 0.0

@export_range(0,6)var noteBookIndex : int = 0:
	get:
		return noteBookIndex
	set(value):
		noteBookIndex = value
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
		object.stamina = object.maxStamina
	# set respawn time for endless mode
	if Global.endless:
		respawnTime = 120.0

func _process(_delta : float) -> void:
	$NoteBook.position.y = sin(Engine.get_frames_drawn() * 0.017453292) / 2.0 + 1.0

func _physics_process(delta : float) -> void:
	# count down respawn time, if the time hits below 0 then respawn
	if respawnTime > 0.0:
		respawnTime -= delta
		# apear and play sound
		if respawnTime <= 0.0:
			visible = true
			$Respawn.play()
