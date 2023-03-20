extends GridMap

signal mark_cell(cell_to_mark)
signal clear_cell(cell_to_clear)

@export var living_cell_lives_with_neighbors_min: int = 2
@export var living_cell_lives_with_neighbors_max: int = 5
@export var dead_cell_lives_with_neighbors: int = 5
@export var bounds: int = 10
@export var min_time: float = 0.2

var counter = 0
var thread
var stop: bool = false
var go_color: Color = Color('f3836b')
var stop_color: Color = Color('bda837')
var msh = mesh_library.get_item_mesh(1)
var time: float = 0
var n3d
var full_cell_array: Array
var empty_cell_array: Array
var expanding_search_exclude: Array

# Called when the node enters the scene tree for the first time.
func _ready():
	n3d = get_parent().get_parent()
	n3d.rayHit.connect(_on_node3d_rayhit)
	# make border
	var b1 = bounds
	for x in range(-b1-1,b1+1):
		for y in range(-b1-1,b1+1):
			for z in range(-b1-1,b1+1):
				var b = 0
				if x == b1 or x == -b1-1:
					b += 1
				if y == b1 or y == -b1-1:
					b += 1
				if z == b1 or z == -b1-1:
					b += 1
				if b > 1:
					set_cell_item(Vector3(x,y,z),1)
	for c in get_used_cells_by_item(0):
		if c.x >= b1 or c.x <= -b1-1 or c.y >= b1 or c.y <= -b1-1 or c.z >= b1 or c.z <= -b1-1:
			set_cell_item(c,-1)
	thread = Thread.new()
	# Third argument is optional userdata, it can be any variable.
	thread.start(Callable(self, "_thread_function"),Thread.PRIORITY_HIGH)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if stop:
		msh.material.albedo_color = stop_color
		msh.radius = 0.5
		msh.height = 1
	else:
		msh.material.albedo_color = go_color
		msh.radius = 0.25
		msh.height = 0.5
	var result = false
	time += delta
	if not thread.is_alive() and not stop and thread.is_started() and time >= min_time:
		result = thread.wait_to_finish()
	if result and not stop:
		time = 0
		thread.start(Callable(self, "_thread_function"))
	if result:
		for e in result[2]:
			set_cell_item(e,-1)
		for f in result[1]:
			set_cell_item(f,0)
		full_cell_array = result[1]
		empty_cell_array = result[2]

# Run here and exit.
# The argument is the userdata passed from start().
# If no argument was passed, this one still needs to
# be here and it will be null.
func _thread_function():
	var empties = []
	var fulls = []
	for x in range(-bounds,bounds):
		for y in range(-bounds,bounds):
			for z in range(-bounds,bounds):
				var loc = Vector3(x,y,z)
				var loc_arr = get_neighbors(x,y,z)
				var item = get_cell_item(loc)
				var counter = 0
				for l in loc_arr:
					l = wrap_loc(l, bounds)
					if get_cell_item(l) == 0:
						counter += 1
				if item == 0:
					if living_cell_lives_with_neighbors_min <= counter and counter <= living_cell_lives_with_neighbors_max:
						fulls.append(loc)
					else:
						empties.append(loc)
				else:
					if counter == dead_cell_lives_with_neighbors:
						fulls.append(loc)
#	for e in empties:
#		set_cell_item(e,-1)
#	for f in fulls:
#		set_cell_item(f,0)
	return ['done', fulls, empties]

# Thread must be disposed (or "joined"), for portability.
func _exit_tree():
	thread.wait_to_finish()
	
func get_neighbors(x,y,z):
	var loc_xL = Vector3(x-1,y,z)
	var loc_xLyL = Vector3(x-1,y-1,z)
	var loc_xLyR = Vector3(x-1,y+1,z)
	var loc_xR = Vector3(x+1,y,z)
	var loc_xRyL = Vector3(x+1,y-1,z)
	var loc_xRyR = Vector3(x+1,y+1,z)
	var loc_yL = Vector3(x,y-1,z)
	var loc_yLzL = Vector3(x,y-1,z-1)
	var loc_yLzR = Vector3(x,y-1,z+1)
	var loc_yR = Vector3(x,y+1,z)
	var loc_yRzL = Vector3(x,y+1,z-1)
	var loc_yRzR = Vector3(x,y+1,z+1)
	var loc_zL = Vector3(x,y,z-1)
	var loc_zLxL = Vector3(x-1,y,z-1)
	var loc_zLxR = Vector3(x+1,y,z-1)
	var loc_zR = Vector3(x,y,z+1)
	var loc_zRxL = Vector3(x-1,y,z+1)
	var loc_zRxR = Vector3(x+1,y,z+1)
	var loc_xLyLzL = Vector3(x-1,y-1,z-1)
	var loc_xRyLzL = Vector3(x+1,y-1,z-1)
	var loc_xLyRzL = Vector3(x-1,y+1,z-1)
	var loc_xRyRzL = Vector3(x+1,y+1,z-1)
	var loc_xLyRzR = Vector3(x-1,y+1,z+1)
	var loc_xRyRzR = Vector3(x+1,y+1,z+1)
	var loc_xLyLzR = Vector3(x-1,y-1,z+1)
	var loc_xRyLzR = Vector3(x+1,y-1,z+1)
	return [loc_xL,loc_xR,loc_yL,loc_yR,loc_zL,loc_zR,loc_xLyL,loc_xLyR,loc_xRyL,loc_xRyR,loc_yLzL,loc_yLzR,
		loc_yRzL,loc_yRzR,loc_zLxL,loc_zLxR,loc_zRxL,loc_zRxR,loc_xLyLzL,loc_xRyLzL,loc_xLyRzL,loc_xRyRzL,loc_xLyRzR,loc_xRyRzR,loc_xLyLzR,loc_xRyLzR]
		
func get_neighbors_search(loc: Vector3i):
	var x = loc.x
	var y = loc.y
	var z = loc.z
	var loc_xL = Vector3(x-1,y,z)
	var loc_xR = Vector3(x+1,y,z)
	var loc_yL = Vector3(x,y-1,z)
	var loc_yR = Vector3(x,y+1,z)
	var loc_zL = Vector3(x,y,z-1)
	var loc_zR = Vector3(x,y,z+1)
	var neighbors = [loc_xL,loc_xR,loc_yL,loc_yR,loc_zL,loc_zR]
	var wrapped_neighbors = []
	for n in neighbors:
		wrapped_neighbors.append(wrap_loc(n,bounds))
	return wrapped_neighbors
	
func wrap_loc(loc, boundaries):
	if loc.x < -boundaries:
		loc.x = boundaries
	if loc.x > boundaries:
		loc.x = -boundaries
	if loc.y < -boundaries:
		loc.y = boundaries
	if loc.y > boundaries:
		loc.y = -boundaries
	if loc.z < -boundaries:
		loc.z = boundaries
	if loc.z > boundaries:
		loc.z = -boundaries
	return loc
	
func find_nearest_living_cell(location, del):
	# check for thread issues in this function
	var l_int = Vector3i(location)
	var l_item = get_cell_item(l_int)
	if l_item == 0:
		expanding_search_exclude = []
		if not del:
			emit_signal("mark_cell", l_int)
		else:
			emit_signal("clear_cell", l_int)
		if Input.is_action_pressed("shift"):
			expanding_search(l_int, expanding_search_exclude, del)
	
func _on_node3d_rayhit(loc, del):
	var hit = local_to_map(loc)
	find_nearest_living_cell(hit, del)
	
func expanding_search(cell: Vector3i, exclude: Array = [], del: bool = false):
	for fc in full_cell_array:
		if fc not in exclude:
			var neighbors = get_neighbors_search(cell)
			if fc in neighbors:
				if not del:
					expanding_search_exclude.append(fc)
					emit_signal("mark_cell", fc)
				else:
					expanding_search_exclude.erase(fc)
					emit_signal("clear_cell", fc)
			
