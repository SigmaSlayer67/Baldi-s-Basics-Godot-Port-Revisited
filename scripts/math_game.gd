extends CanvasLayer

const VU_COUNT = 16
const FREQ_MAX = 11050.0
const MIN_DB = 60.0

var spectrum
var getFrame = 0.0

@onready var liveBaldiReaction = $Pad/LiveBaldiReaction

@onready var mathDialogue = $MathDialogue
@onready var music = $Music
@onready var results = [$Pad/Result1,
$Pad/Result2,
$Pad/Result3,
]

@onready var numberLineEdit = $Pad/Answer
@onready var LineEditRegEx = RegEx.new()
var old_text = ""

var hintText = ["I GET ANGRIER FOR EVERY PROBLEM YOU GET WRONG",
"I HEAR EVERY DOOR YOU OPEN",]

var audioQueue = []

@export var correctTexture = preload("res://graphics/YCTPTextures/Check.png")
@export var incorrectTexture = preload("res://graphics/YCTPTextures/X.png")

@onready var questions = $Pad/Questions
var questionOverlaps = []

@export var bal_plus = preload("res://audio/Characters/Baldi/MathGame/BAL_Math_Plus.wav")
@export var bal_minus = preload("res://audio/Characters/Baldi/MathGame/BAL_Math_Minus.wav")
@export var bal_times = preload("res://audio/Characters/Baldi/MathGame/BAL_Math_Times.wav")
@export var bal_divide = preload("res://audio/Characters/Baldi/MathGame/Unused/BAL_Math_Divided.wav")
@export var bal_equels = preload("res://audio/Characters/Baldi/MathGame/BAL_Math_Equals.wav")
@export var bal_howto = preload("res://audio/Characters/Baldi/MathGame/Intro/BAL_General_HowTo.wav")
@export var bal_intro = preload("res://audio/Characters/Baldi/MathGame/Intro/BAL_Math_Intro.wav")
@export var bal_screech = preload("res://audio/Characters/Baldi/Sounds/BAL_Screech.wav")

var bal_numbers = [
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
var problemAudio = [
preload("res://audio/Characters/Baldi/MathGame/Problems/BAL_General_Problem1.wav"),
preload("res://audio/Characters/Baldi/MathGame/Problems/BAL_General_Problem2.wav"),
preload("res://audio/Characters/Baldi/MathGame/Problems/BAL_General_Problem3.wav")
]

var impossible = false

var endDelay = 5.0

var problem = 0
var wrongAnswers = 0
var solution = 0

func _ready():
	Global.unlock_mouse()
	LineEditRegEx.compile("^-?[0-9]*$")
	# get spectrum
	spectrum = AudioServer.get_bus_effect_instance(3,0)
	if Global.endless:
		hintText = ["That's more like it...","Keep up the good work or see me after class...",]
	if Global.noteBooks == 0:
		queue_audio(bal_intro)
		queue_audio(bal_howto)
	new_problems()
	# hide baldi if scary
	liveBaldiReaction.visible = !Global.spoopMode
	if !Global.spoopMode:
		music.play()
	# connect buttons
	for i:TextureButton in $Pad/Keypad.get_children():
		i.pressed.connect(parse_button.bind(i))

func _process(delta):
	# calculate soudn volume for lip sync
	var hzOffset = 1.5
	var hz = hzOffset * FREQ_MAX / VU_COUNT
	var prevHz = (hzOffset-1.0) * FREQ_MAX / VU_COUNT

	var magnitude = spectrum.get_magnitude_for_frequency_range(hz,prevHz).length()
	var volume = (clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1))
	if !mathDialogue.playing:
		volume = 0.0
		# queue next audio
		if audioQueue.size() > 0 && !Global.spoopMode:
			mathDialogue.stream = audioQueue[0]
			mathDialogue.play()
			audioQueue.pop_front()
	
	getFrame = lerp(getFrame,snappedf(volume,0.1),delta*16.0)
	if !Global.spoopMode:
		liveBaldiReaction.frame = round(getFrame*6.0)
	
	if problem > 3:
		endDelay -= 1.0 * delta
		if endDelay <= 0:
			Global.noteBooks += 1 # global uses a get set function on notebook
			queue_free()
			Global.lock_mouse()
			get_tree().paused = false



func new_problems():
	numberLineEdit.clear()
	if problem <= 2:
		queue_audio(problemAudio[problem])
		if (problem <= 1 || Global.noteBooks <= 0):
			var nums = [randi_range(0,9),randi_range(0,9)]
			# determine if + or -
			var getSign = sign(randf()-0.5)
			var symbol = "+"
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
			questionOverlaps.append(questions)
			# create 2 label duplicated
			var textDuplicate = questions.duplicate()
			$Pad.add_child(textDuplicate)
			questionOverlaps.append(textDuplicate)
			# third duplciate
			textDuplicate = questions.duplicate()
			$Pad.add_child(textDuplicate)
			questionOverlaps.append(textDuplicate)
			# overlap the questions so it looks garbled
			for i in questionOverlaps.size():
				var nums = [randi_range(1,9999),randi_range(1,9999),randi_range(1,9999)]
				var getSign = sign(randf()-0.5)
				var symbol = "+"
				solution = nums[0]+nums[1]
				if getSign < 0:
					symbol = "-"
				var secondSymbol = "/"
				if getSign < 0:
					secondSymbol = "x"
				questionOverlaps[i].text = "SOLVE MATH Q"+str(problem+1)+":\n"+str(nums[0])+symbol+str(nums[1])+secondSymbol+str(nums[2])+"="
				# add audio on first loop
				if i == 0:
					queue_audio(bal_plus if getSign >= 0 else bal_minus)
					queue_audio(bal_screech)
					queue_audio(bal_divide if getSign >= 0 else bal_times)
					queue_audio(bal_screech)
					queue_audio(bal_equels)
					
			
	else:
		# clear duplicate texts
		if questionOverlaps.size() > 1:
			questionOverlaps[1].queue_free()
			questionOverlaps[2].queue_free()
		if !Global.spoopMode:
			questions.text = "WOW! YOU EXIST!"
		elif !Global.endless && wrongAnswers >= 3:
			questions.text = "I HEAR MATH THAT BAD"
			Global.faildBooks += 1
		else:
			questions.text = hintText[int(round(randf()))]
			
			
	problem += 1
	


func _on_LineEdit_text_changed(new_text):
	var caretPos = numberLineEdit.caret_column
	if LineEditRegEx.search(new_text):
		old_text = str(new_text)
	else:
		numberLineEdit.text = old_text
		numberLineEdit.caret_column = caretPos-1

func queue_audio(audio:AudioStream = null):
	audioQueue.append(audio)


func _on_answer_text_submitted(_new_text):
	if problem <= 3:
		# reset math dialogue
		mathDialogue.stop()
		audioQueue.clear()
		if solution == int(numberLineEdit.text) && numberLineEdit.text != "" && !impossible: # check that the answer matches
			results[problem-1].texture = correctTexture
			Global.secret = false
			queue_audio(praises)
		else:
			if wrongAnswers == 0 && music.playing:
				music.stream = load("res://audio/Music/mus_hang.wav")
				music.play()
				# play anger animation
				$Pad/BaldiAnimator.play("Anger")
			wrongAnswers += 1
			results[problem-1].texture = incorrectTexture
			if !Global.spoopMode:
				Global.spoopMode = true
				for i in get_tree().get_nodes_in_group("pre_game"):
					if i is AudioStreamPlayer:
						i.stop()
					else:
						i.queue_free()
				for i in get_tree().get_nodes_in_group("activatable"):
					if i.has_method("activate"):
						i.activate()
			
			if !Global.endless:
				if problem >= 3:
					Global.baldi.get_angry(1.0) # add 1.0 anger
				else:
					Global.baldi.get_temp_anger(0.25) # add 0.25 to temp anger
				# check if all notebooks are collection
				if Global.noteBooks >= 6 && !Global.escapeMode:
					Global.escapeMode = true
					for i in get_tree().get_nodes_in_group("escape"):
						if i.has_method("escape_activate"):
							i.escape_activate()
					
			else:
				Global.baldi.get_angry(1.0) # add 1.0
		new_problems()

func parse_button(button:TextureButton):
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
