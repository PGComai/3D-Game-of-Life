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
@onready var control = $"../../../../../../.."
@onready var building_plane = $BuildingPlane
@onready var height_wall = $HeightPlane/HeightWall
@onready var cam_hinge = $CamHinge


var y_adjust = false
var y_height: float = 0.0
var bounds = 0
var y_sens = 0.1

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	
func _unhandled_input(event):
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global.stop and global.build:
		if Input.is_action_pressed("shift") and control.looking:
			pass
		else:
			y_adjust = false
			var pp = pointer(2)
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
	bg.visible = global.build
	plane_grid_map.visible = global.build

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


func _on_grid_holder_child_entered_tree(node):
	if global:
		global.build = false
		bounds = node.bounds

func _on_build_grid_wall_go_here(loc):
	height_wall.global_position = loc


func _on_sub_viewport_container_gui_input(event: InputEvent):
	if global.stop:
		if global.build:
			if Input.is_action_pressed("shift"):
				if event is InputEventMouseMotion:
					y_height += event.relative.y * y_sens
					y_height = clampf(y_height, -2*bounds, 2*bounds-2)
					building_plane.global_position.y = snapped(y_height, 2.0)
					emit_signal("adjust_build_cube_y", y_height)
		else:
			pass
	else:
		pass
