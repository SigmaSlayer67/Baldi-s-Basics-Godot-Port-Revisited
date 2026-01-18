@tool
extends Area3D

@export var itemIndex:Global.ITEMS = Global.ITEMS.ZESTI:
	get:
		return itemIndex
	set(value):
		itemIndex = value
		if get_node_or_null("Sprite") != null:
			if Engine.is_editor_hint():
				# you'll have to copy the texture array for this to display right
				var itemTextures = [
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
				get_node("Sprite").texture = itemTextures[value]
			else:
				get_node("Sprite").texture = Global.itemTextures[value]

@onready var isActive = visible

func interact(object):
	if !visible:
		return
	visible = false
	# give player stamina
	if object is Player:
		object.add_item(itemIndex)

func activate():
	if !isActive:
		visible = true
		isActive = true

func _process(_delta):
	$Sprite.position.y = sin(Engine.get_frames_drawn() * 0.017453292) / 2.0 + 1.0
