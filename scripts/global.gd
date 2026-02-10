# ATTENTION: Script done! (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
extends Node

signal note_books_updated
var MathGame : PackedScene = preload("res://entities/math_game.tscn")

var player : Player = null
var bully : Bully = null
var baldi : Baldi = null
var crafters : Crafters = null
var background : WorldEnvironment = null

var endless : bool = false
var secret : bool = true # secret exit for if you fail all note books

enum ITEMS {NONE, ZESTI, LOCK, KEY, BSODA, QUARTER, TAPE, ALARM, NO_SQUEE, SCISSORS, BOOTS}
var itemTextures : Array[Texture2D] = [
null,
preload("res://graphics/SchoolHouse/PickUps/EnergyFlavoredZestyBar.png"),
preload("res://graphics/SchoolHouse/PickUps/YellowDoorLock.png"),
preload("res://graphics/SchoolHouse/PickUps/Key.png"),
preload("res://graphics/SchoolHouse/PickUps/BSODA.png"),
preload("res://graphics/SchoolHouse/PickUps/Quarter.png"),
preload("res://graphics/SchoolHouse/PickUps/Tape.png"),
preload("res://graphics/SchoolHouse/PickUps/AlarmClockItem.png"),
preload("res://graphics/SchoolHouse/PickUps/wd_nosquee.png"),
preload("res://graphics/SchoolHouse/PickUps/SafetyScissors.png"),
preload("res://graphics/SchoolHouse/PickUps/BootsIcon.png")
]

var audMachineQuite : AudioStream = preload("res://audio/SFX/FinalMode/quiet noise loop.wav")
var audMachineStart : AudioStream = preload("res://audio/SFX/FinalMode/LoudNoiseIntroLoop.wav")
var audMachineRev : AudioStream = preload("res://audio/SFX/FinalMode/Loud noise 3.wav")

var noteBooks : int = 0:
	get:
		return noteBooks
	set(value):
		noteBooks = value
		note_books_updated.emit()
var faildBooks : int = 0

var spoopMode : bool = false

var escapeMode : bool = false
var escapesReached : int = 0

#region options
var sensativity : float = 20.0
var analog : bool = true
var rumble : bool = true
#endregion

func get_wander_point(group : StringName = "wander", min_range : int = 0, max_range : int = 99999) -> Vector3:
	var wanderPoints : Array[Node] = get_tree().get_nodes_in_group(group)
	var getPoint : Vector3 = wanderPoints[randi_range(min_range,min(wanderPoints.size()-1,max_range))].global_position
	for i : Node in get_tree().get_nodes_in_group("ambience"):
		if i is Ambience:
			i.play_ambience(getPoint)
	return getPoint # set target

func reset_values() -> void:
	noteBooks = 0
	player = null
	baldi = null
	background = null
	spoopMode = false
	escapeMode = false
	secret = true
	escapesReached = 0

func exit_reached() -> void:
	# if you're looking for the exit level routine it's handled in the door script
	escapesReached += 1
	match(int(escapesReached)):
		1: # first exit
			# set scene to red
			for i : Node in get_tree().get_nodes_in_group("first_exit_trigger"):
				if i is WorldEnvironment:
					i.environment.ambient_light_color = Color.RED
				elif i is AudioStreamPlayer: # play machine noise
					i.stream = audMachineQuite
					i.play()
		2: # second exit
			for i : Node in get_tree().get_nodes_in_group("second_exit_trigger"):
				if i is AudioStreamPlayer: # play machine noise
					i.volume_db = -20.0 # lower volume so that you don't blow up someone's speakers
					i.stream = audMachineStart
					i.play()
		3: # third exit
			for i : Node in get_tree().get_nodes_in_group("third_exit_trigger"):
				if i is AudioStreamPlayer: # play machine noise
					i.volume_db = -20.0 # lower volume so that you don't blow up someone's speakers
					i.stream = audMachineRev
					i.play()

func lock_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func unlock_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func save_settings() -> void:
	# Create new ConfigFile object.
	var config := ConfigFile.new()
	config.set_value("settings", "sensativity", sensativity)
	config.set_value("settings", "analog", analog)
	config.set_value("settings", "rumble", rumble)
	# Save it to a file (overwrite if already exists).
	config.save("user://settings.cfg")

func load_settings() -> void:
	var config := ConfigFile.new()
	# Load data from a file.
	var err : Error = config.load("user://settings.cfg")
	
	# If the file didn't load, ignore it.
	if err != OK:
		return
	
	sensativity = config.get_value("settings", "sensativity")
	analog = config.get_value("settings", "analog")
	rumble = config.get_value("settings", "rumble")
