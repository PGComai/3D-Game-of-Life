extends GridMap

signal wall_go_here(loc)

@onready var grid_holder = $"../GridHolder"
@onready var node_3d = $".."

var buildCursor: Vector3i
var bounds: int

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global.build:
		set_cell_item(buildCursor,0)

func _on_node_3d_build_ray(loc):
	var hit = local_to_map(loc)
	var to_clear = get_used_cells()
	for tc in to_clear:
		if tc == hit:
			pass
		else:
			set_cell_item(tc,-1)
	var hitbounds = bounds - 1
	hit.x = clamp(hit.x,-hitbounds-1,hitbounds)
	hit.y = clamp(hit.y,-hitbounds-1,hitbounds)
	hit.z = clamp(hit.z,-hitbounds-1,hitbounds)
	buildCursor = hit
	emit_signal('wall_go_here', map_to_local(hit))

func _on_grid_holder_child_entered_tree(node):
	bounds = node.bounds

func _on_node_3d_adjust_build_cube_y(y):
	var new_y = local_to_map(Vector3(0,y,0))
	buildCursor.y = new_y.y
	var to_clear = get_used_cells()
	for tc in to_clear:
		if tc == buildCursor:
			pass
		else:
			set_cell_item(tc,-1)
