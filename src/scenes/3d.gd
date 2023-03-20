extends Node3D

signal rayHit(loc, del)

@export var cursor_loc: Vector3i

@onready var cam = $CamHinge/Camera3D

var stop = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if stop and Input.is_action_pressed("click"):
		var pp = pointer()
		if pp:
			emit_signal("rayHit",(pp[0]-pp[1]),false)
	elif stop and Input.is_action_pressed("rclick"):
		var pp = pointer()
		if pp:
			emit_signal("rayHit",(pp[0]-pp[1]),true)

func pointer():
	var spaceState = get_world_3d().direct_space_state
	var mousePos = get_viewport().get_mouse_position()
	var camera = cam
	var rayStart = camera.project_ray_origin(mousePos)
	var rayEnd = rayStart + camera.project_ray_normal(mousePos) * 2000
	var query = PhysicsRayQueryParameters3D.create(rayStart, rayEnd, 1)
	var rayDict = spaceState.intersect_ray(query)

	if rayDict.has('position'):
		return [rayDict['position'],rayDict['normal']]
	return null

func _on_control_stop():
	stop = true

func _on_control_go():
	stop = false
