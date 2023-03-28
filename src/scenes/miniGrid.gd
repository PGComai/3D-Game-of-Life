extends Node3D

@onready var panel = $"../../../../.."
@onready var grid_map = $GridMap
@onready var camhinge = $camhinge
@onready var camera_3d = $camhinge/CamVOffset/Camera3D

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
	# get center from max and min values, not average
	var tx = []
	var ty = []
	var tz = []
	for p in points:
		tx.append(p.x)
		ty.append(p.y)
		tz.append(p.z)
	var max_x = tx.max()
	var max_y = ty.max()
	var max_z = tz.max()
	var min_x = tx.min()
	var min_y = ty.min()
	var min_z = tz.min()
	var center_x = max_x - ((max_x - min_x)/2)
	var center_y = max_y - ((max_y - min_y)/2)
	var center_z = max_z - ((max_z - min_z)/2)
	var center = Vector3(center_x, center_y, center_z)
	var dists = []
	for p in points:
		dists.append(Vector3(p).distance_squared_to(Vector3(center)))
		grid_map.set_cell_item(Vector3i(p), 0)
	var max_dist = sqrt(dists.max())
	camhinge.global_position = center*2
	camera_3d.size = clamp((max_dist * 15) * (log(max_dist)/5.5), 15, 70)
	
func rotate_cam(delta):
	camhinge.rotation.y += delta

func _on_panel_mouse_entered():
	rotating = true

func _on_panel_mouse_exited():
	rotating = false
