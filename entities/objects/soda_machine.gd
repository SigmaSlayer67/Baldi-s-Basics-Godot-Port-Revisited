extends StaticBody3D

var material = [null,preload("res://graphics/Material/ZestiMachine.tres")]
var pickUp = [Global.ITEMS.BSODA,Global.ITEMS.ZESTI]

@export_enum("BSODA","ZESTI") var machineType = 0:
	get:
		return machineType
	set(value):
		machineType = value
		$FrontTexture.material_override = material[value]

func use_quarter(player : Player):
	player.add_item(pickUp[machineType])
