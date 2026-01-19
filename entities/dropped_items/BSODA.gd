extends Area3D

var npcList : Array[Node3D] = []
@export var speed : float = 20.0
var lifeTime : float = 30.0
@onready var soda : MeshInstance3D = $SODA


func _ready() -> void:
	# 1 looks better with viewport
	if get_tree().root.content_scale_mode == get_tree().root.CONTENT_SCALE_MODE_VIEWPORT:
		soda.mesh.material["shader_parameter/tile_scale"] = 1

func _physics_process(delta : float) -> void:
	translate(Vector3.FORWARD*delta*speed) # move forward
	
	if lifeTime > 0:
		lifeTime -= delta # decrease life span
	else:
		queue_free() # clear when lifespan timer runs out
	
	for i : Node3D in npcList: # shift other npcs
		if i.get("velocity") != null: # check that velocity exists
			var setVelocity : Vector3 = -global_basis.z*speed
			# set to position then move
			if i is CharacterBody3D:
				var collide : KinematicCollision3D = i.move_and_collide(setVelocity * delta,true)
				if collide:
					setVelocity = setVelocity.slide(collide.get_normal()).normalized()*setVelocity.length()
			i.velocity = Vector3(setVelocity.x,i.velocity.y,setVelocity.z)
			if i.get("navSkipSafe") != null:
				i.navSkipSafe = true

func _on_body_entered(body : Node3D) -> void:
	if body == self: return
	npcList.append(body)

func _on_body_exited(body : Node3D) -> void:
	if npcList.has(body):
		npcList.erase(body) # remove npc (if they're on the list)
