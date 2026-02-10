# ATTENTION: Script done! (check message that says: the script is fully statically typed and ready for execution, shall be removed when moving on to the next branch)
extends StaticBody3D

var material : Array[BaseMaterial3D] = [null,preload("res://graphics/Material/ZestiMachine.tres")]
var pickUp : Array[Global.ITEMS] = [Global.ITEMS.BSODA,Global.ITEMS.ZESTI]

@export_enum("BSODA","ZESTI") var machineType : int = 0:
	get:
		return machineType
	set(value):
		machineType = value
		$FrontTexture.material_override = material[value]


func use_quarter(player : Player) -> void:
	player.add_item(pickUp[machineType])
