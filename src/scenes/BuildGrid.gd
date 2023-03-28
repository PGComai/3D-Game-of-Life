extends GridMap

@onready var grid_holder = $"../GridHolder"
@onready var building_grid_mesh = $"../BuildingPlane/buildingGridMesh"
@onready var node_3d = $".."

var buildCursor: Vector3i
var bounds: int

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if node_3d.build:
		set_cell_item(buildCursor,0)
		building_grid_mesh.global_position = map_to_local(buildCursor)

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

func _on_grid_holder_child_entered_tree(node):
	bounds = node.bounds
