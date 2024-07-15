extends Node3D

signal rayHit(loc, del)
signal buildRay(loc)
signal adjust_build_cube_y(y)
signal build_new_block(loc)
signal delete_block(loc)

@export var cursor_loc: Vector3i

@onready var cam = $CamHinge/Camera3D
@onready var bg = $BuildGrid
@onready var plane_grid_map = $BuildingPlane/PlaneGridMap
@onready var control = $"../../../../../.."
@onready var building_plane = $BuildingPlane
@onready var height_wall = $HeightPlane/HeightWall
@onready var cam_hinge = $CamHinge

var stop = false
var build = false
var y_adjust = false
var y_height = 0
var bounds = 0
var y_sens = 0.1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _unhandled_input(event):
	if event is InputEventMouseMotion and y_adjust:
		y_height -= event.relative.y * y_sens


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if stop and Input.is_action_pressed("click") and not build:
		var pp = pointer(0b00000000000000000001)
		if pp:
			emit_signal("rayHit",(pp[0]-pp[1]),false)
	elif stop and Input.is_action_pressed("rclick") and not build:
		var pp = pointer(0b00000000000000000001)
		if pp:
			emit_signal("rayHit",(pp[0]-pp[1]),true)
	elif stop and build:
		if Input.is_action_pressed("shift") and control.looking:
			y_adjust = true
			height_wall.rotation.y = cam_hinge.rotation.y
			var pp = pointer(0b00000000000000000100)
			if pp:
				y_height = pp[0].y
				y_height = clamp(y_height, -2*bounds, 2*bounds-2)
				y_height = snapped(y_height, 2)
				building_plane.global_position.y = y_height
				emit_signal("adjust_build_cube_y", y_height)
		else:
			y_adjust = false
			var pp = pointer(0b00000000000000000010)
			if pp:
				var target = pp[0]
				# this bit is necessary for good grid snapping
				if target.y >= 0:
					target += Vector3(1,1,1)
					target = target.snapped(Vector3(2,2,2))
					target -= Vector3(1,0.5,1)
				else:
					target += Vector3(1,-1,1)
					target = target.snapped(Vector3(2,2,2))
					target -= Vector3(1,-0.5,1)
				var t = Vector3i(target)
				emit_signal("buildRay", t)
				if Input.is_action_pressed("click"):
					#add block
					emit_signal("build_new_block", t)
				elif Input.is_action_pressed("rclick"):
					#delete block
					emit_signal("delete_block", t)
	bg.visible = build
	plane_grid_map.visible = build

func pointer(coll_layer):
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
	build = false

func _on_control_build():
	build = !build

func _on_grid_holder_child_entered_tree(node):
	build = false
	bounds = node.bounds

func _on_build_grid_wall_go_here(loc):
	height_wall.global_position = loc
