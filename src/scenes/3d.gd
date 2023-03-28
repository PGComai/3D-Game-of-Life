extends Node3D

signal rayHit(loc, del)
signal buildRay(loc)

@export var cursor_loc: Vector3i

@onready var cam = $CamHinge/Camera3D
@onready var bg = $BuildGrid
@onready var building_grid_mesh = $BuildingPlane/buildingGridMesh
@onready var plane_grid_map = $BuildingPlane/PlaneGridMap

var stop = false
var build = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if stop and Input.is_action_pressed("click") and not build:
		var pp = pointer(1)
		if pp:
			emit_signal("rayHit",(pp[0]-pp[1]),false)
	elif stop and Input.is_action_pressed("rclick") and not build:
		var pp = pointer(1)
		if pp:
			emit_signal("rayHit",(pp[0]-pp[1]),true)
	elif stop and build:
		var pp = pointer(2)
		if pp:
			emit_signal("buildRay", Vector3i(pp[0]))
	
	bg.visible = build
	plane_grid_map.visible = build
	#building_grid_mesh.visible = build

func pointer(coll_layer: int):
	var spaceState = get_world_3d().direct_space_state
	var mousePos = get_viewport().get_mouse_position()
	var rayStart = cam.project_ray_origin(mousePos)
	var rayEnd = rayStart + cam.project_ray_normal(mousePos) * 2000
	var query = PhysicsRayQueryParameters3D.create(rayStart, rayEnd, coll_layer)
	var rayDict = spaceState.intersect_ray(query)

	if rayDict.has('position'):
		return [rayDict['position'],rayDict['normal']]
	return null

func _on_control_stop():
	stop = true

func _on_control_go():
	stop = false

func _on_control_build():
	build = !build

func _on_grid_holder_child_entered_tree(node):
	build = false
