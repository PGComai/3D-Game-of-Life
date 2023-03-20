extends Node3D

@onready var panel = $"../../../../.."
@onready var grid_map = $GridMap
@onready var camhinge = $camhinge
@onready var camera_3d = $camhinge/Camera3D

var rotating = false

# Called when the node enters the scene tree for the first time.
func _ready():
	make_map(panel.cells)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if rotating:
		rotate_cam(delta)
	else:
		camhinge.rotation.y = lerp_angle(camhinge.rotation.y, 0, 0.1)

func make_map(points: Array[Vector3]):
	var tx = 0
	var ty = 0
	var tz = 0
	for p in points:
		tx += p.x
		ty += p.y
		tz += p.z
	var arr_len = len(points)
	var center = Vector3i(tx/arr_len, ty/arr_len, tz/arr_len)
	var dists = []
	for p in points:
		dists.append(Vector3(p).distance_squared_to(Vector3(center)))
		grid_map.set_cell_item(Vector3i(p), 0)
	var max_dist = sqrt(dists.max())
	camhinge.global_position = center
	camera_3d.size = max_dist * 6
	
func rotate_cam(delta):
	camhinge.rotation.y += delta

func _on_panel_mouse_entered():
	rotating = true

func _on_panel_mouse_exited():
	rotating = false
