extends CharacterBody3D
class_name Player

var gameOver = false
var jumpRope = false
var sweeping = false
var hugging = false
var boots = false
var bootTime = 0.0

var slowSpeed = 4.0
var walkSpeed = 10.0
var runSpeed = 16.0
var playerSpeed = 0.0

const GRAVITY = 10.0
var initVelocity = 5.0
var jumpVelocity = 0.0
var jumpHeight = 0.0

@onready var stamina = maxStamina
var staminaRate = 10.0
var maxStamina = 100.0

@onready var guilt = initGuilt
var initGuilt = 0.0
var guiltType = ""

@onready var castCollider = $Camera3D/Collider
@onready var lastCameraPosition = $Camera3D.global_position
@onready var cameraOffset = $Camera3D.position
@onready var camera3D = $Camera3D

var cameraTween : Tween
var cameraVTween : Tween

var detentionTimer = 0.0

var failSafe = 0.0

var BlackBackground = preload("res://graphics/black_background_environment.tres")

var BSoda = preload("res://entities/dropped_items/BSODA.tscn")

@export_enum("Off","On","Funny") var debugMode = 0
@export var real_game = true # used to determine if the players in a game environment or walking evnironment, used to hide the hud in secret ending

@onready var frozenPosition = global_position

var itemSelected = 0
var items = []

var run_toggled = false # for mobile
var behind_toggled = false # for mobile

var itemNames = [
	"Nothing",
	"Energy flavored Zesty Bar",
	"Yellow Door Lock",
	"Principal's Keys",
	"BSODA",
	"Quarter",
	"Baldi Anti Hearing and Disorienting Tape",
	"Alarm Clock",
	"WD-NoSquee (Door Type)",
	"Safety Scissors",
	"Big Ol' Boots",
]
@onready var slots = $PlayerHud/ItemSlots/ItemSlots

var turnRate = 0.0

var is_mobile = DisplayServer.is_touchscreen_available()

const ALARM_CLOCK = preload("res://entities/objects/alarm_clock.tscn")

func _ready():
	Global.player = self
	Global.lock_mouse()
	
	items.resize(slots.get_child_count())
	items.fill(Global.ITEMS.NONE)
	update_items()
	
	# mobile support for item slots
	if is_mobile:
		for i in slots.get_child_count():
			var slot = slots.get_child(i)
			slot.gui_input.connect(func(input):
				if input is InputEventScreenTouch:
					set_selected_item(i)
				)
	
	if !is_mobile:
		$PlayerHud/Buttons.visible = false
		$PlayerHud/Pause.visible = false
	
	Global.note_books_updated.connect(update_note_book_counter)
	
	# hide hud for secret ending
	if !real_game:
		# hide all children by default
		for i in $PlayerHud.get_children():
			i.hide()
		# show reticle (pointer is unhidden automatically)
		$PlayerHud/Reticle.show()
	
	# funny debug (make the player ultra fast)
	if debugMode:
		walkSpeed *= 5

func _process(delta):
	# look behind
	camera3D.rotation.y = 0.0 if (!Input.is_action_pressed("gm_behind") and !behind_toggled) || jumpRope else deg_to_rad(180.0)
	
	$PlayerHud/Detention.visible = detentionTimer > 0
	$PlayerHud/Detention/Label.text = "You have detention! \n" + str(int(ceil(detentionTimer))) + " seconds remain!"
	$PlayerHud/StaminaBar.value = (stamina / maxStamina) * 100
	$PlayerHud/Warning.visible = stamina < 0.0
	update_note_book_counter()
	
	# rotation code
	rotate_y(deg_to_rad(turnRate*delta*Global.sensativity*8.0))
	turnRate = -Input.get_axis("gm_turn_left","gm_turn_right")
	if !Global.analog:
		turnRate = round(turnRate)
	
	# head animation handler (see baldi for the func call method, see baldi_react for the other)
	var headReaction := $PlayerHud/BaldiHeadController/HeadReaction
	# scroll out of frame if not playing
	if !headReaction.is_playing():
		headReaction.position.y = move_toward(headReaction.position.y,64.0,delta*60.0*8.0)
	else: # else set it to an onscreen position
		headReaction.position.y = -64.0


func _physics_process(delta):
	player_move(delta)
	stamina_check(delta)
	guilt_check(delta)
	
	if failSafe > 0.0:
		failSafe = move_toward(failSafe,0.0,delta)
	else:
		hugging = false
		sweeping = false
	
	# boots
	bootTime = move_toward(bootTime,0.0,delta)
	boots = bootTime > 0
	
	# check for interacts for pointer visibility
	# set pointer to invisible by default (sometimes the object collider might collide with nothing)
	$PlayerHud/Pointer.visible = false
	if castCollider.is_colliding():
		var hit = castCollider.get_collider()
		if hit is Door:
			# special handling for double doors (don't want to make it into a different class)
			$PlayerHud/Pointer.visible = !hit.doubleDoor && hit.visible
		else:
			$PlayerHud/Pointer.visible = hit.has_method("interact") && hit.visible

func player_move(delta):
	var direction = Input.get_vector("gm_left","gm_right","gm_back","gm_forward")
	direction = Vector3(direction.x,0.0,-direction.y)
	if stamina > 0:
		if Input.is_action_pressed("gm_run") or run_toggled:
			playerSpeed = runSpeed
			if velocity.length() > 0.1 && !hugging && !sweeping:
				reset_guilt("running",0.1)
		else:
			playerSpeed = walkSpeed
	else:
		playerSpeed = walkSpeed
		
	var moveDirection = direction * playerSpeed
	
	if jumpRope:
		moveDirection = Vector3.ZERO
	if jumpRope || jumpHeight > 0: # continue jump routine if the players still in the air
		# jumping
		jumpVelocity -= GRAVITY*delta
		jumpHeight = max(0,jumpHeight+(jumpVelocity*delta))
		# set v_offset (jumping)
		if cameraVTween:
			cameraVTween.kill()
		# use tween for smooth transitions
		cameraVTween = create_tween()
		cameraVTween.tween_property(camera3D,"v_offset",jumpHeight,delta)
	
	if !velocity.is_equal_approx(Vector3.ZERO): # comment this line out to always move and slide (pushes you out of geometry)
		var collider = move_and_collide(velocity*delta,true)
		if collider:
			move_and_collide(velocity.slide(velocity.slide(collider.get_normal()).normalized()) * delta)
			velocity = velocity.slide(collider.get_normal())
		
		velocity.y = 0
		move_and_slide()
		camera3D.global_translate(-get_real_velocity()*delta)
	velocity = moveDirection.rotated(basis.y,rotation.y)
	
	if cameraTween:
		cameraTween.kill()
	cameraTween = create_tween()
	cameraTween.tween_property(camera3D,"position",cameraOffset,delta)
	
	# jump rope check
	if jumpRope && global_position.distance_to(frozenPosition) >= 1.0:
		jumpRope = false

func stamina_check(delta):
	if velocity.length() > 0.1:
		if (Input.is_action_pressed("gm_run") or run_toggled) && stamina > 0.0:
			stamina -= staminaRate * delta
		if stamina <= 0.0 && stamina > -5.0:
			stamina = -5.0
	elif stamina < maxStamina:
		stamina += staminaRate * delta
		
func _unhandled_input(event): # For multi drag
	var sensativity = Global.sensativity/100.0
	if event is InputEventScreenDrag:
		if !Global.analog:
			turnRate = sign(-event.relative.x)
		else:
			rotate_y(deg_to_rad(-event.relative.x*sensativity))
			
func _input(event):
	var sensativity = Global.sensativity/100.0
	if event is InputEventMouseMotion and not is_mobile:
		if !Global.analog:
			turnRate = sign(-event.relative.x)
		else:
			rotate_y(deg_to_rad(-event.relative.x*sensativity))
	
		
	
	if jumpRope:
		if event.is_action_pressed("gm_jump") && jumpHeight <= 0.0: # jumping for jumprope minigame
			jumpVelocity = initVelocity # start jump
	elif event.is_action_pressed("gm_click") && castCollider.is_colliding():
		# interact with objects
		if not is_mobile:
			on_click()
	
	if event.is_action_pressed("gm_next_item"):
		set_selected_item(itemSelected+1)
	elif event.is_action_pressed("gm_prev_item"):
		set_selected_item(itemSelected-1)
	elif event.is_action_pressed("gm_first_item"):
		set_selected_item(0)
	elif  event.is_action_pressed("gm_second_item"):
		set_selected_item(1)
	elif  event.is_action_pressed("gm_third_item"):
		set_selected_item(2)
	
	if event.is_action_pressed("gm_use"):
		use_item()
	
	# pause menu
	if event.is_action_pressed("gm_pause"):
		get_tree().paused = true
		Global.unlock_mouse()
		await get_tree().process_frame
		Options.show()
		await Options.closed
		get_tree().paused = false
		Global.lock_mouse()

func on_click():
	var hit = castCollider.get_collider()
	if hit and hit.has_method("interact"):
		hit.interact(self)

func reset_guilt(type, amount):
	if amount >= guilt:
		guilt = amount
		guiltType = type

func guilt_check(delta):
	if guilt > 0:
		guilt = move_toward(guilt,0.0,delta)
	detentionTimer = move_toward(detentionTimer,0.0,delta)

func game_over():
	if debugMode == 2:
		Global.baldi.move_and_collide(-camera3D.global_basis.z*100.0)
	if debugMode > 0: return
	camera3D.process_mode = Node.PROCESS_MODE_ALWAYS
	if is_instance_valid(Global.baldi):
		camera3D.global_position = Global.baldi.global_position+Global.baldi.global_position.direction_to(Vector3(global_position.x,Global.baldi.global_position.y,global_position.z))*2.0+Vector3(0,1,0)
		camera3D.look_at(Global.baldi.global_position+Vector3(0,1,0),up_direction)
	$Caught.play() # volume turned down because I don't wanna be responcible for blowing out someoen's speakers.
	# if you have a problem with me doing that cry about it.
	$PlayerHud.visible = false
	Global.background.environment = BlackBackground
	# clipping
	var tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	camera3D.far = 200.0
	tween.tween_property(camera3D,"far",0.0,1.0).set_trans(Tween.TRANS_LINEAR)
	
	get_tree().paused = true
	await tween.finished # wait for clip to finish
	get_tree().paused = false
	Global.reset_values()
	get_tree().change_scene_to_file("res://scenes/gameover.tscn")

func update_note_book_counter():
	if Global.endless:
		$PlayerHud/NoteBookCount.text = str(Global.noteBooks)+" Notebooks"
	else:
		$PlayerHud/NoteBookCount.text = str(Global.noteBooks)+"/7 Notebooks"

func set_selected_item(newItemSelect):
	slots.get_child(itemSelected).color = Color.WHITE
	itemSelected = wrapi(newItemSelect,0,slots.get_child_count())
	slots.get_child(itemSelected).color = Color.RED
	update_items()

func use_item():
	match(items[itemSelected]):
		Global.ITEMS.ZESTI: # ZESTI BAR! refills past max stamina
			stamina = maxStamina * 2.0
			items[itemSelected] = Global.ITEMS.NONE
		Global.ITEMS.BSODA: # Create BSODA!
			var mySoda = BSoda.instantiate()
			get_parent().add_child(mySoda)
			reset_guilt("drink",1.0)
			mySoda.global_position = global_position
			# set bsoda rotation to camera rotation
			mySoda.global_rotation = camera3D.global_rotation
			items[itemSelected] = Global.ITEMS.NONE
		Global.ITEMS.LOCK: # Lock double doors
			# interact with objects
			var hit = castCollider.get_collider()
			if hit:
				if hit.has_method("lock_double_door"):
					if hit.lock_double_door():
						items[itemSelected] = Global.ITEMS.NONE
		Global.ITEMS.KEY: # Unlock Principal door
			# interact with objects
			var hit = castCollider.get_collider()
			if hit:
				if hit.has_method("use_key"):
					if hit.use_key():
						items[itemSelected] = Global.ITEMS.NONE
		Global.ITEMS.QUARTER:
			# interact with objects
			var hit = castCollider.get_collider()
			if hit:
				if hit.has_method("use_quarter"):
					items[itemSelected] = Global.ITEMS.NONE
					hit.use_quarter(self)
		Global.ITEMS.NO_SQUEE: # no squee
			# interact with objects
			var hit = castCollider.get_collider()
			if hit:
				if hit.has_method("no_squee"):
					if hit.no_squee():
						$NoSquee.play()
						items[itemSelected] = Global.ITEMS.NONE
		Global.ITEMS.TAPE:
			# interact with objects
			var hit = castCollider.get_collider()
			if hit:
				if hit.has_method("use_tape"):
					items[itemSelected] = Global.ITEMS.NONE
					hit.use_tape(self)
		Global.ITEMS.BOOTS:
			items[itemSelected] = Global.ITEMS.NONE
			# stop first prize from hugging
			hugging = false
			# set boot time to 15
			bootTime = 15.0
			# tween animation (move boots over screen)
			$PlayerHud/Boots.show()
			var tween = get_tree().create_tween()
			$PlayerHud/Boots.position.y = -128.0
			tween.tween_property($PlayerHud/Boots,"position:y",get_viewport().size.y,1.0)
			await tween.finished
			$PlayerHud/Boots.hide()
		Global.ITEMS.ALARM:
			# place alarm clock and remove item, pretty simple
			var clock = ALARM_CLOCK.instantiate()
			add_sibling(clock)
			clock.global_position = global_position
			items[itemSelected] = Global.ITEMS.NONE
		Global.ITEMS.SCISSORS:
			# reset collission mask to only check for characters (set a memory value)
			var memory = castCollider.collision_mask
			castCollider.collision_mask = 0
			castCollider.set_collision_mask_value(4,true)
			castCollider.force_raycast_update()
			# reset
			castCollider.collision_mask = memory
			# interact with characters
			var hit = castCollider.get_collider()
			if hit:
				if hit.has_method("scissors"):
					if hit.scissors():
						items[itemSelected] = Global.ITEMS.NONE
			# playtime check
			elif jumpRope:
				for i in get_tree().get_nodes_in_group("playtime"):
					if i is PlayTime:
						if i.jumpRopeStarted:
							if i.scissors():
								items[itemSelected] = Global.ITEMS.NONE

	update_items()

func add_item(itemID):
	var currentGetItem = 0
	while items[min(currentGetItem,items.size()-1)] != Global.ITEMS.NONE && currentGetItem < items.size():
		currentGetItem += 1
	if currentGetItem >= items.size(): # if all slots are filled, overwrite item
		currentGetItem = itemSelected
	items[currentGetItem] = itemID
	update_items()

func lose_item(item):
	items[item] = 0
	update_items()
	

func update_items():
	for i in items.size():
		slots.get_child(i).get_child(0).texture = Global.itemTextures[items[i]]
	$PlayerHud/ItemText.text = itemNames[items[itemSelected]]

func escape_activate():
	$AllNotebooks.play()

func bali_react(react_frame = "Notice"):
	$PlayerHud/BaldiHeadController/HeadReaction.play(react_frame)
	


func _on_run_button_pressed() -> void:
	run_toggled = !run_toggled


func _on_behind_button_pressed() -> void:
	behind_toggled = !behind_toggled


func _on_click_button_pressed() -> void:
	on_click()
	Input.action_press("gm_jump")
