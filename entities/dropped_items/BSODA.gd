extends Area3D

var npcList = []
@export var speed = 20.0
var lifeTime = 30.0
@onready var soda = $SODA


func _ready():
	# 1 looks better with viewport
	if get_tree().root.content_scale_mode == get_tree().root.CONTENT_SCALE_MODE_VIEWPORT:
		soda.mesh.material["shader_parameter/tile_scale"] = 1

func _physics_process(delta):
	translate(Vector3.FORWARD*delta*speed) # move forward
	
	if lifeTime > 0:
		lifeTime -= delta # decrease life span
	else:
		queue_free() # clear when lifespan timer runs out
	
	for i in npcList: # shift other npcs
		if i.get("velocity") != null: # check that velocity exists
			var setVelocity = -global_basis.z*speed
			# set to position then move
			if i is CharacterBody3D:
				var collide = i.move_and_collide(setVelocity * delta,true)
				if collide:
					setVelocity = setVelocity.slide(collide.get_normal()).normalized()*setVelocity.length()
			i.velocity = Vector3(setVelocity.x,i.velocity.y,setVelocity.z)
			if i.get("navSkipSafe") != null:
				i.navSkipSafe = true

func _on_body_entered(body):
	if body == self: return
	npcList.append(body)

func _on_body_exited(body):
	if npcList.has(body):
		npcList.erase(body) # remove npc (if they're on the list)
