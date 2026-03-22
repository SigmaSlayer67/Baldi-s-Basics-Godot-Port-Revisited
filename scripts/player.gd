# ATTENTION: Script donenot  (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
extends CharacterBody3D
class_name Player

var game_over : bool = false
var jump_rope : bool = false
var sweeping : bool = false
var hugging : bool = false
var boots : bool = false
var boot_time : float = 0.0

var slow_speed : float = 4.0
var walk_speed : float = 10.0
var run_speed : float = 16.0
var player_speed : float = 0.0

const GRAVITY : float = 10.0
var init_velocity : float = 5.0
var jump_velocity : float = 0.0
var jump_height : float = 0.0

@onready var stamina : float = max_stamina
var stamina_rate : float = 10.0
var max_stamina : float = 100.0

@onready var guilt : float = init_guilt
var init_guilt : float = 0.0
var guilt_type : StringName = ""

@onready var cast_collider : RayCast3D = $Camera3D/Collider
@onready var last_camera_position : Vector3 = $Camera3D.global_position
@onready var camera_offset : Vector3 = $Camera3D.position
@onready var camera_3d : Camera3D = $Camera3D

var camera_tween : Tween
var camera_v_tween : Tween

var detention_timer : float = 0.0

var fail_safe : float = 0.0

var black_background : Environment = preload("res://graphics/black_background_environment.tres")

var bsoda : PackedScene = preload("res://entities/dropped_items/BSODA.tscn")

@export_enum("Off","On","Funny") var debug_mode : int = 0
@export var real_game : bool = true # used to determine if the players in a game environment or walking evnironment, used to hide the hud in secret ending

@onready var frozen_position : Vector3 = global_position

var item_selected : int = 0
var items : PackedInt32Array = []

var run_toggled : bool = false # for mobile
var behind_toggled : bool = false # for mobile

var item_names : PackedStringArray = [
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
@onready var slots : Control = $PlayerHud/ItemSlots/ItemSlots

var turn_rate : float = 0.0

var is_mobile : bool = DisplayServer.is_touchscreen_available()

const ALARM_CLOCK : PackedScene = preload("res://entities/objects/alarm_clock.tscn")

func _ready() -> void:
	Global.player = self
	Global.lock_mouse()
	
	items.resize(slots.get_child_count())
	items.fill(Global.ITEMS.NONE)
	update_items()
	
	# mobile support for item slots
	if is_mobile:
		for i : int in slots.get_child_count():
			var slot : Node = slots.get_child(i)
			slot.gui_input.connect(func(input : InputEvent) -> void:
				if input is InputEventScreenTouch:
					set_selected_item(i)
				)
	
	if not is_mobile:
		$PlayerHud/Buttons.visible = false
		$PlayerHud/Pause.visible = false
	
	Global.note_books_updated.connect(update_note_book_counter)
	
	# hide hud for secret ending
	if not real_game:
		# hide all children by default
		for i : Node in $PlayerHud.get_children():
			i.hide()
		# show reticle (pointer is unhidden automatically)
		$PlayerHud/Reticle.show()
	
	# funny debug (make the player ultra fast)
	if debug_mode == 2:
		walk_speed *= 5.0

func _process(delta : float) -> void:
	# look behind
	camera_3d.rotation.y = 0.0 if (not Input.is_action_pressed("gm_behind") and not behind_toggled) or jump_rope else deg_to_rad(180.0)
	
	$PlayerHud/Detention.visible = detention_timer > 0
	$PlayerHud/Detention/Label.text = "You have detentionnot  \n" + str(int(ceil(detention_timer))) + " seconds remainnot "
	$PlayerHud/StaminaBar.value = (stamina / max_stamina) * 100.0
	$PlayerHud/Warning.visible = stamina < 0.0
	update_note_book_counter()
	
	# rotation code
	rotate_y(deg_to_rad(turn_rate*delta*Global.sensitivity*8.0))
	turn_rate = -Input.get_axis("gm_turn_left","gm_turn_right")
	if not Global.analog:
		turn_rate = round(turn_rate)
	
	# head animation handler (see baldi for the func call method, see baldi_react for the other)
	var headReaction : AnimatedSprite2D = $PlayerHud/BaldiHeadController/HeadReaction
	# scroll out of frame if not playing
	if not headReaction.is_playing():
		headReaction.position.y = move_toward(headReaction.position.y,64.0,delta*60.0*8.0)
	else: # else set it to an onscreen position
		headReaction.position.y = -64.0


func _physics_process(delta : float) -> void:
	player_move(delta)
	stamina_check(delta)
	guilt_check(delta)
	
	if fail_safe > 0.0:
		fail_safe = move_toward(fail_safe,0.0,delta)
	else:
		hugging = false
		sweeping = false
	
	# boots
	boot_time = move_toward(boot_time,0.0,delta)
	boots = boot_time > 0.0
	
	# check for interacts for pointer visibility
	# set pointer to invisible by default (sometimes the object collider might collide with nothing)
	$PlayerHud/Pointer.visible = false
	if cast_collider.is_colliding():
		var hit : Object = cast_collider.get_collider()
		if hit is Door:
			# special handling for double doors (don't want to make it into a different class)
			$PlayerHud/Pointer.visible = not hit.doubleDoor and hit.visible
		else:
			$PlayerHud/Pointer.visible = hit.has_method("interact") and hit.visible

func player_move(delta : float) -> void:
	## ATTENTION: This might break something, but i had no other choice except for doing this
	## for the sake of static typing. 
	var input_dir : Vector2 = Input.get_vector("gm_left","gm_right","gm_back","gm_forward")
	var direction := Vector3(input_dir.x,0.0,-input_dir.y)
	if stamina > 0:
		if Input.is_action_pressed("gm_run") or run_toggled:
			player_speed = run_speed
			if velocity.length() > 0.1 and not hugging and not sweeping:
				reset_guilt("running",0.1)
		else:
			player_speed = walk_speed
	else:
		player_speed = walk_speed
		
	var moveDirection : Vector3 = direction * player_speed
	
	if jump_rope:
		moveDirection = Vector3.ZERO
	if jump_rope or jump_height > 0.0: # continue jump routine if the players still in the air
		# jumping
		jump_velocity -= GRAVITY*delta
		jump_height = max(0.0,jump_height+(jump_velocity*delta))
		# set v_offset (jumping)
		if camera_v_tween:
			camera_v_tween.kill()
		# use tween for smooth transitions
		camera_v_tween = create_tween()
		camera_v_tween.tween_property(camera_3d,"v_offset",jump_height,delta)
	
	if not velocity.is_equal_approx(Vector3.ZERO): # comment this line out to always move and slide (pushes you out of geometry)
		var collider : KinematicCollision3D = move_and_collide(velocity*delta,true)
		if collider:
			move_and_collide(velocity.slide(velocity.slide(collider.get_normal()).normalized()) * delta)
			velocity = velocity.slide(collider.get_normal())
		
		velocity.y = 0.0
		move_and_slide()
		camera_3d.global_translate(-get_real_velocity()*delta)
	velocity = moveDirection.rotated(basis.y,rotation.y)
	
	if camera_tween:
		camera_tween.kill()
	camera_tween = create_tween()
	camera_tween.tween_property(camera_3d,"position",camera_offset,delta)
	
	# jump rope check
	if jump_rope and global_position.distance_to(frozen_position) >= 1.0:
		jump_rope = false

func stamina_check(delta : float) -> void:
	if velocity.length() > 0.1:
		if (Input.is_action_pressed("gm_run") or run_toggled) and stamina > 0.0:
			stamina -= stamina_rate * delta
		if stamina <= 0.0 and stamina > -5.0:
			stamina = -5.0
	elif stamina < max_stamina:
		stamina += stamina_rate * delta
		
func _unhandled_input(event : InputEvent) -> void: # For multi drag
	var sensativity : float = Global.sensitivity/100.0
	if event is InputEventScreenDrag:
		if not Global.analog:
			turn_rate = sign(-event.relative.x)
		else:
			rotate_y(deg_to_rad(-event.relative.x*sensativity))
			
func _input(event : InputEvent) -> void:
	var sensativity : float = Global.sensitivity/100.0
	if event is InputEventMouseMotion and not is_mobile:
		if not Global.analog:
			turn_rate = sign(-event.relative.x)
		else:
			rotate_y(deg_to_rad(-event.relative.x*sensativity))
	# I wonder if whoever was making this code had a stroke and got this horrible spacing
	
		
	
	if jump_rope:
		if event.is_action_pressed("gm_jump") and jump_height <= 0.0: # jumping for jumprope minigame
			jump_velocity = init_velocity # start jump
	elif event.is_action_pressed("gm_click") and cast_collider.is_colliding():
		# interact with objects
		if not is_mobile:
			on_click()
	
	if event.is_action_pressed("gm_next_item"):
		set_selected_item(item_selected+1)
	elif event.is_action_pressed("gm_prev_item"):
		set_selected_item(item_selected-1)
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

func on_click() -> void:
	var hit : Object = cast_collider.get_collider()
	if hit and hit.has_method("interact"):
		hit.interact(self)

func reset_guilt(type : StringName, amount : float) -> void:
	if amount >= guilt:
		guilt = amount
		guilt_type = type

func guilt_check(delta : float) -> void:
	if guilt > 0.0:
		guilt = move_toward(guilt,0.0,delta)
	detention_timer = move_toward(detention_timer,0.0,delta)

func game_over() -> void:
	if debug_mode == 2:
		Global.baldi.move_and_collide(-camera_3d.global_basis.z*100.0)
	if debug_mode > 0: return
	camera_3d.process_mode = Node.PROCESS_MODE_ALWAYS
	if is_instance_valid(Global.baldi):
		# Goodnes, we might have to fix this spacing sooner than later
		camera_3d.global_position = Global.baldi.global_position+Global.baldi.global_position.direction_to(Vector3(global_position.x,Global.baldi.global_position.y,global_position.z))*2.0+Vector3(0.0,1.0,0.0)
		camera_3d.look_at(Global.baldi.global_position+Vector3(0.0,1.0,0.0),up_direction)
	$Caught.play() # volume turned down because I don't wanna be responcible for blowing out someoen's speakers.
	# if you have a problem with me doing that cry about it.
	$PlayerHud.visible = false
	Global.background.environment = black_background
	# clipping
	var tween : Tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	camera_3d.far = 200.0
	tween.tween_property(camera_3d,"far",0.0,1.0).set_trans(Tween.TRANS_LINEAR)
	
	get_tree().paused = true
	await tween.finished # wait for clip to finish
	get_tree().paused = false
	Global.reset_values()
	get_tree().change_scene_to_file("res://scenes/gameover.tscn")

func update_note_book_counter() -> void:
	if Global.endless:
		$PlayerHud/NoteBookCount.text = str(Global.note_books)+" Notebooks"
	else:
		$PlayerHud/NoteBookCount.text = str(Global.note_books)+"/7 Notebooks"

func set_selected_item(new_item_select : int) -> void:
	slots.get_child(item_selected).color = Color.WHITE
	item_selected = wrapi(new_item_select,0,slots.get_child_count())
	slots.get_child(item_selected).color = Color.RED
	update_items()

# This function is just a monstrousity, it would be great if more parts are separated on their own
# more abstract and underlined functions to reduce the amount of duplicated code.
func use_item() -> void:
	match(items[item_selected]):
		Global.ITEMS.ZESTI: # ZESTI BARnot  refills past max stamina
			stamina = max_stamina * 2.0
			items[item_selected] = Global.ITEMS.NONE
		Global.ITEMS.BSODA: # Create BSODAnot 
			var mySoda := bsoda.instantiate() as Area3D
			get_parent().add_child(mySoda)
			reset_guilt("drink",1.0)
			mySoda.global_position = global_position
			# set bsoda rotation to camera rotation
			mySoda.global_rotation = camera_3d.global_rotation
			items[item_selected] = Global.ITEMS.NONE
		Global.ITEMS.LOCK: # Lock double doors
			# interact with objects
			var hit : Object = cast_collider.get_collider()
			if hit:
				if hit.has_method("lock_double_door"):
					if hit.lock_double_door():
						items[item_selected] = Global.ITEMS.NONE
		Global.ITEMS.KEY: # Unlock Principal door
			# interact with objects
			var hit : Object = cast_collider.get_collider()
			if hit:
				if hit.has_method("use_key"):
					if hit.use_key():
						items[item_selected] = Global.ITEMS.NONE
		Global.ITEMS.QUARTER:
			# interact with objects
			var hit : Object = cast_collider.get_collider()
			if hit:
				if hit.has_method("use_quarter"):
					items[item_selected] = Global.ITEMS.NONE
					hit.use_quarter(self)
		Global.ITEMS.NO_SQUEE: # no squee
			# interact with objects
			var hit : Object = cast_collider.get_collider()
			if hit:
				if hit.has_method("no_squee"):
					if hit.no_squee():
						$NoSquee.play()
						items[item_selected] = Global.ITEMS.NONE
		Global.ITEMS.TAPE:
			# interact with objects
			var hit : Object = cast_collider.get_collider()
			if hit:
				if hit.has_method("use_tape"):
					items[item_selected] = Global.ITEMS.NONE
					hit.use_tape(self)
		Global.ITEMS.BOOTS:
			items[item_selected] = Global.ITEMS.NONE
			# stop first prize from hugging
			hugging = false
			# set boot time to 15
			boot_time = 15.0
			# tween animation (move boots over screen)
			$PlayerHud/Boots.show()
			var tween : Tween = get_tree().create_tween()
			$PlayerHud/Boots.position.y = -128.0
			tween.tween_property($PlayerHud/Boots,"position:y",get_viewport().size.y,1.0)
			await tween.finished
			$PlayerHud/Boots.hide()
		Global.ITEMS.ALARM:
			# place alarm clock and remove item, pretty simple
			var clock := ALARM_CLOCK.instantiate() as Node3D
			add_sibling(clock)
			clock.global_position = global_position
			items[item_selected] = Global.ITEMS.NONE
		Global.ITEMS.SCISSORS:
			# reset collission mask to only check for characters (set a memory value)
			var memory : int = cast_collider.collision_mask
			cast_collider.collision_mask = 0
			cast_collider.set_collision_mask_value(4,true)
			cast_collider.force_raycast_update()
			# reset
			cast_collider.collision_mask = memory
			# interact with characters
			var hit : Object = cast_collider.get_collider()
			if hit:
				if hit.has_method("scissors"):
					if hit.scissors():
						items[item_selected] = Global.ITEMS.NONE
			# playtime check
			elif jump_rope:
				for i : Node in get_tree().get_nodes_in_group("playtime"):
					if i is PlayTime:
						if i.jump_ropeStarted:
							if i.scissors():
								items[item_selected] = Global.ITEMS.NONE

	update_items()

func add_item(itemID : int) -> void:
	var currentGetItem : int = 0
	while items[min(currentGetItem,items.size()-1)] not = Global.ITEMS.NONE and currentGetItem < items.size():
		currentGetItem += 1
	if currentGetItem >= items.size(): # if all slots are filled, overwrite item
		currentGetItem = item_selected
	items[currentGetItem] = itemID
	update_items()

func lose_item(item : int) -> void:
	items[item] = 0
	update_items()
	

func update_items() -> void:
	for i : int in items.size():
		slots.get_child(i).get_child(0).texture = Global.item_textures[items[i]]
	$PlayerHud/ItemText.text = item_names[items[item_selected]]

func escape_activate() -> void:
	$AllNotebooks.play()

func bali_react(react_frame : StringName = "Notice") -> void:
	$PlayerHud/BaldiHeadController/HeadReaction.play(react_frame)


func _on_run_button_pressed() -> void:
	run_toggled = not run_toggled


func _on_behind_button_pressed() -> void:
	behind_toggled = not behind_toggled


func _on_click_button_pressed() -> void:
	on_click()
	Input.action_press("gm_jump")
