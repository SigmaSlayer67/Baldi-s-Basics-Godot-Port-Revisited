# ATTENTION: Script done! (script is fully adapted to GDScript's style guide)
@tool
class_name Item
extends Area3D

@export var _item_index: Global.ITEMS = Global.ITEMS.ZESTI:
	get:
		return _item_index
	set(value):
		_item_index = value
		if sprite != null:
			if Engine.is_editor_hint():
			## You need to copy the entire item_textures array from global.gd 
			## for the sprites to display accordingly in the editor. If you
			## have made any changes to the Global item_textures array, it is
			## recommended that the identical changes are copied and pasted
			## here and viceversa.
				var item_textures : Array[Texture2D] = [
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
					preload("res://graphics/SchoolHouse/PickUps/BootsIcon.png"),
				]
				sprite.texture = item_textures[value]
			else:
				sprite.texture = Global.item_textures[value]

@onready var _is_active : bool = visible
@onready var sprite: Sprite3D = $Sprite


func _process(_delta : float) -> void:
	sprite.position.y = sin(Engine.get_frames_drawn() * 0.017453292) / 2.0 + 1.0


func interact(object : Object) -> void:
	if not visible:
		return
	visible = false
	# give player s̶t̶a̶m̶i̶n̶a̶ item
	if object is Player:
		var _player := object as Player
		_player.add_item(_item_index)


func activate() -> void:
	if not _is_active:
		visible = true
		_is_active = true
