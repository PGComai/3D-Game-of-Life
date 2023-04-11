extends GridMap

signal save_cells(cells)
signal selected
signal not_selected

var control

# Called when the node enters the scene tree for the first time.
func _ready():
	control = get_tree().root.get_node('Control')
	control.go.connect(_on_control_go)
	control.save_requested.connect(_on_control_save_requested)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if len(get_used_cells()) > 0:
		emit_signal("selected")
	else:
		emit_signal("not_selected")
	
func update_cursor(location: Vector3i):
	var used_cells = get_used_cells()
	if len(used_cells) > 0:
		for uc in used_cells:
			set_cell_item(uc, -1)
	set_cell_item(local_to_map(location), 0)
	
func clear_cursor():
	var used_cells = get_used_cells()
	if len(used_cells) > 0:
		for uc in used_cells:
			set_cell_item(uc, -1)

func _on_control_go():
	clear_cursor()

func _on_grid_map_mark_cell(cell_to_mark):
	print('mark cell')
	set_cell_item(cell_to_mark, 0)

func _on_grid_map_clear_cell(cell_to_clear):
	set_cell_item(cell_to_clear, -1)

func _on_control_save_requested():
	emit_signal("save_cells", get_used_cells())
