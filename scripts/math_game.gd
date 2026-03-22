# ATTENTION: Script donenot  (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
extends CanvasLayer

const VU_COUNT : int = 16
const FREQ_MAX : float = 11050.0
const MIN_DB : float = 60.0

var spectrum : AudioEffectInstance
var get_frame : float = 0.0

@onready var live_baldi_reaction : Sprite2D = $Pad/LiveBaldiReaction

@onready var math_dialogue : AudioStreamPlayer = $MathDialogue
@onready var music : AudioStreamPlayer = $Music
@onready var results : Array[TextureRect] = [$Pad/Result1,
$Pad/Result2,
$Pad/Result3,
]

@onready var number_line_edit : LineEdit = $Pad/Answer
@onready var line_edit_regex := RegEx.new()
var old_text : String = ""

var hint_text : PackedStringArray = ["I GET ANGRIER FOR EVERY PROBLEM YOU GET WRONG",
"I HEAR EVERY DOOR YOU OPEN",]

var audio_queue : Array[AudioStream] = []

@export var correct_texture : Texture2D = preload("res://graphics/YCTPTextures/Check.png")
@export var incorrect_texture : Texture2D = preload("res://graphics/YCTPTextures/X.png")

@onready var questions : Label = $Pad/Questions
var question_overlaps : Array[Label] = []

@export var bal_plus : AudioStream = preload("res://audio/Characters/Baldi/MathGame/BAL_Math_Plus.wav")
@export var bal_minus : AudioStream = preload("res://audio/Characters/Baldi/MathGame/BAL_Math_Minus.wav")
@export var bal_times : AudioStream = preload("res://audio/Characters/Baldi/MathGame/BAL_Math_Times.wav")
@export var bal_divide : AudioStream = preload("res://audio/Characters/Baldi/MathGame/Unused/BAL_Math_Divided.wav")
@export var bal_equals : AudioStream = preload("res://audio/Characters/Baldi/MathGame/BAL_Math_Equals.wav")
@export var bal_howto : AudioStream = preload("res://audio/Characters/Baldi/MathGame/Intro/BAL_General_HowTo.wav")
@export var bal_intro : AudioStream = preload("res://audio/Characters/Baldi/MathGame/Intro/BAL_Math_Intro.wav")
@export var bal_screech : AudioStream = preload("res://audio/Characters/Baldi/Sounds/BAL_Screech.wav")

var bal_numbers : Array[AudioStream] = [
preload("res://audio/Characters/Baldi/MathGame/Numbers/BAL_Math_0.wav"),
preload("res://audio/Characters/Baldi/MathGame/Numbers/BAL_Math_1.wav"),
preload("res://audio/Characters/Baldi/MathGame/Numbers/BAL_Math_2.wav"),
preload("res://audio/Characters/Baldi/MathGame/Numbers/BAL_Math_3.wav"),
preload("res://audio/Characters/Baldi/MathGame/Numbers/BAL_Math_4.wav"),
preload("res://audio/Characters/Baldi/MathGame/Numbers/BAL_Math_5.wav"),
preload("res://audio/Characters/Baldi/MathGame/Numbers/BAL_Math_6.wav"),
preload("res://audio/Characters/Baldi/MathGame/Numbers/BAL_Math_7.wav"),
preload("res://audio/Characters/Baldi/MathGame/Numbers/BAL_Math_8.wav"),
preload("res://audio/Characters/Baldi/MathGame/Numbers/BAL_Math_9.wav"),
]

@export var praises = AudioStreamRandomizer
var problem_audio : Array[AudioStream] = [
preload("res://audio/Characters/Baldi/MathGame/Problems/BAL_General_Problem1.wav"),
preload("res://audio/Characters/Baldi/MathGame/Problems/BAL_General_Problem2.wav"),
preload("res://audio/Characters/Baldi/MathGame/Problems/BAL_General_Problem3.wav")
]

var impossible : bool = false

var end_delay : float = 5.0

var problem : int = 0
var wrong_answers : int = 0
var solution : int = 0

func _ready() -> void:
	Global.unlock_mouse()
	line_edit_regex.compile("^-?[0-9]*$")
	# get spectrum
	spectrum = AudioServer.get_bus_effect_instance(3,0)
	if Global.endless:
		hint_text = ["That's more like it...","Keep up the good work or see me after class...",]
	if Global.note_books == 0:
		queue_audio(bal_intro)
		queue_audio(bal_howto)
	new_problems()
	# hide baldi if scary
	live_baldi_reaction.visible = not Global.spoop_mode
	if not Global.spoop_mode:
		music.play()
	# connect buttons
	for i : TextureButton in $Pad/Keypad.get_children():
		i.pressed.connect(parse_button.bind(i))


func _process(delta : float) -> void:
	# calculate soudn volume for lip sync
	var hz_offset : float = 1.5
	var hz : float = hz_offset * FREQ_MAX / VU_COUNT
	var prev_hz : float = (hz_offset-1.0) * FREQ_MAX / VU_COUNT

	var magnitude : float = spectrum.get_magnitude_for_frequency_range(hz,prev_hz).length()
	var volume : float = (clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1))
	if not math_dialogue.playing:
		volume = 0.0
		# queue next audio
		if audio_queue.size() > 0 and not Global.spoop_mode:
			math_dialogue.stream = audio_queue[0]
			math_dialogue.play()
			audio_queue.pop_front()
	
	get_frame = lerp(get_frame,snappedf(volume,0.1),delta*16.0)
	if not Global.spoop_mode:
		live_baldi_reaction.frame = round(get_frame*6.0)
	
	if problem > 3:
		end_delay -= 1.0 * delta
		if end_delay <= 0:
			Global.note_books += 1 # global uses a get set function on notebook
			queue_free()
			Global.lock_mouse()
			get_tree().paused = false



func new_problems() -> void:
	numberLineEdit.clear()
	if problem <= 2:
		queue_audio(problem_audio[problem])
		if (problem <= 1 or Global.note_books <= 0):
			var nums : PackedInt32Array = [randi_range(0,9),randi_range(0,9)]
			# determine if + or -
			var getSign : int = sign(randf()-0.5)
			var symbol : String = "+"
			solution = nums[0]+nums[1]
			if getSign < 0:
				symbol = "-"
				solution = nums[0]-nums[1]
			questions.text = "SOLVE MATH Q"+str(problem+1)+":\n\n"+str(nums[0])+symbol+str(nums[1])+"="
			queue_audio(bal_numbers[nums[0]])
			# determine audio based on the sign direction
			queue_audio(bal_plus if getSign >= 0 else bal_minus)
			queue_audio(bal_numbers[nums[1]])
		else:
			impossible = true
			# screech first answer
			queue_audio(bal_screech)
			# add question to the overlap list
			question_overlaps.append(questions)
			# create 2 label duplicated
			var textDuplicate : Node = questions.duplicate()
			$Pad.add_child(textDuplicate)
			question_overlaps.append(textDuplicate)
			# third duplciate
			textDuplicate = questions.duplicate()
			$Pad.add_child(textDuplicate)
			question_overlaps.append(textDuplicate)
			# overlap the questions so it looks garbled
			for i : int in question_overlaps.size():
				var nums : PackedInt64Array = [randi_range(1,9999),randi_range(1,9999),randi_range(1,9999)]
				var getSign : int = sign(randf()-0.5)
				var symbol : String = "+"
				solution = nums[0]+nums[1]
				if getSign < 0:
					symbol = "-"
				var secondSymbol : String = "/"
				if getSign < 0:
					secondSymbol = "x"
				question_overlaps[i].text = "SOLVE MATH Q"+str(problem+1)+":\n"+str(nums[0])+symbol+str(nums[1])+secondSymbol+str(nums[2])+"="
				# add audio on first loop
				if i == 0:
					queue_audio(bal_plus if getSign >= 0 else bal_minus)
					queue_audio(bal_screech)
					queue_audio(bal_divide if getSign >= 0 else bal_times)
					queue_audio(bal_screech)
					queue_audio(bal_equals)
					
			
	else:
		# clear duplicate texts
		if question_overlaps.size() > 1:
			question_overlaps[1].queue_free()
			question_overlaps[2].queue_free()
		if not Global.spoop_mode:
			questions.text = "WOWnot  YOU EXISTnot "
		elif not Global.endless and wrong_answers >= 3:
			questions.text = "I HEAR MATH THAT BAD"
			Global.failed_books += 1
		else:
			questions.text = hint_text[int(round(randf()))]
			
			
	problem += 1
	


func _on_LineEdit_text_changed(new_text : String) -> void:
	var caretPos : int = numberLineEdit.caret_column
	if line_edit_regex.search(new_text):
		old_text = str(new_text)
	else:
		numberLineEdit.text = old_text
		numberLineEdit.caret_column = caretPos-1

func queue_audio(audio : AudioStream = null) -> void:
	audio_queue.append(audio)


func _on_answer_text_submitted(_new_text : String) -> void:
	if problem <= 3:
		# reset math dialogue
		math_dialogue.stop()
		audio_queue.clear()
		if solution == int(numberLineEdit.text) and numberLineEdit.text not = "" and not impossible: # check that the answer matches
			results[problem-1].texture = correct_texture
			Global.secret = false
			queue_audio(praises)
		else:
			if wrong_answers == 0 and music.playing:
				music.stream = load("res://audio/Music/mus_hang.wav")
				music.play()
				# play anger animation
				$Pad/BaldiAnimator.play("Anger")
			wrong_answers += 1
			results[problem-1].texture = incorrect_texture
			if not Global.spoop_mode:
				Global.spoop_mode = true
				for i : Node in get_tree().get_nodes_in_group("pre_game"):
					if i is AudioStreamPlayer:
						i.stop()
					else:
						i.queue_free()
				for i : Node in get_tree().get_nodes_in_group("activatable"):
					if i.has_method("activate"):
						i.activate()
			
			if not Global.endless:
				if problem >= 3:
					Global.baldi.get_angry(1.0) # add 1.0 anger
				else:
					Global.baldi.get_temp_anger(0.25) # add 0.25 to temp anger
				# check if all notebooks are collection
				if Global.note_books >= 6 and not Global.escapeMode:
					Global.escapeMode = true
					for i : Node in get_tree().get_nodes_in_group("escape"):
						if i.has_method("escape_activate"):
							i.escape_activate()
					
			else:
				Global.baldi.get_angry(1.0) # add 1.0
		new_problems()

func parse_button(button : TextureButton) -> void:
	# parse button pressed based on name
	match(button.name):
		"OK":
			_on_answer_text_submitted(numberLineEdit.text)
		"-":
			if numberLineEdit.text.begins_with("-"):
				numberLineEdit.text = numberLineEdit.text.right(-1)
			else:
				numberLineEdit.text = numberLineEdit.text.insert(0,"-")
		"C":
			numberLineEdit.clear()
		_:
			numberLineEdit.text += button.name
