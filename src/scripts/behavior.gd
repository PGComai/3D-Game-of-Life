extends GridMap

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

# Called when the node enters the scene tree for the first time.
func _ready():
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
	var result = 'not done'
	time += delta
	if not thread.is_alive() and not stop and thread.is_started() and time >= min_time:
		result = thread.wait_to_finish()
	if result == 'done' and not stop:
		time = 0
		thread.start(Callable(self, "_thread_function"))

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
				var loc_arr = [loc_xL,loc_xR,loc_yL,loc_yR,loc_zL,loc_zR,loc_xLyL,loc_xLyR,loc_xRyL,loc_xRyR,loc_yLzL,loc_yLzR,
				loc_yRzL,loc_yRzR,loc_zLxL,loc_zLxR,loc_zRxL,loc_zRxR,loc_xLyLzL,loc_xRyLzL,loc_xLyRzL,loc_xRyRzL,loc_xLyRzR,loc_xRyRzR,loc_xLyLzR,loc_xRyLzR]
				var item = get_cell_item(loc)
				var counter = 0
				for l in loc_arr:
					if l.x < -bounds:
						l.x = bounds
					if l.x > bounds:
						l.x = -bounds
					if l.y < -bounds:
						l.y = bounds
					if l.y > bounds:
						l.y = -bounds
					if l.z < -bounds:
						l.z = bounds
					if l.z > bounds:
						l.z = -bounds
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
	for e in empties:
		set_cell_item(e,-1)
	for f in fulls:
		set_cell_item(f,0)
	return 'done'

# Thread must be disposed (or "joined"), for portability.
func _exit_tree():
	thread.wait_to_finish()
