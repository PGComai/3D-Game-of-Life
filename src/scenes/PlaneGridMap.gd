extends GridMap

var bounds: int

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_grid_holder_child_entered_tree(node):
	bounds = node.bounds
	make_grid()

func make_grid():
	var b1 = bounds
	var z = 0
	for x in range(-b1,b1):
		for y in range(-b1,b1):
			set_cell_item(Vector3i(x,y,z), 0)
