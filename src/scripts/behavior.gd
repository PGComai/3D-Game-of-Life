extends GridMap

signal mark_cell(cell_to_mark)
signal clear_cell(cell_to_clear)
signal send_bounds(b)

@export var living_cell_lives_with_neighbors_min: int = 2
@export var living_cell_lives_with_neighbors_max: int = 5
@export var dead_cell_lives_with_neighbors: int = 5
@export var bounds: int = 10
@export_enum('CPU','GPU') var compute_type: int = 0
@export var img2d: Image
@export var use_noise := false
@export var initial_noise: FastNoiseLite
@export var noise_threshold: float = 0.1

#@onready var comp = preload("res://comp.glsl")


var min_time: float = 0.2
var counter = 0
var thread: Thread
var go_color: Color = Color('f3836b')
var stop_color: Color = Color('bda837')
var msh = mesh_library.get_item_mesh(1)
var time: float = 0.0
var n3d
var full_cell_array: Array
var empty_cell_array: Array
var expanding_search_exclude: Array
var buildCursor: Vector3i
var done: bool
var new_blocks := false
var mutex
var wgsize: int
var tick := true
var gpu_started := false
var just_resumed := false


var gc := GPUComputer.new()

var global: Node


@onready var timer = $Timer
@onready var testmesh = $testmesh


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	mutex = Mutex.new()
	emit_signal("send_bounds", bounds)
	### get this signal to work with bound adjustments ###
	n3d = get_parent().get_parent()
	n3d.rayHit.connect(_on_node3d_rayhit)
	n3d.build_new_block.connect(_on_node3d_build_new_block)
	n3d.delete_block.connect(_on_node3d_delete_block)
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
	
	if use_noise:
		for x in range(-bounds,bounds):
			for y in range(-bounds,bounds):
				for z in range(-bounds,bounds):
					var loc = Vector3(x,y,z)
					var nval = initial_noise.get_noise_3dv(loc)
					if nval > noise_threshold:
						set_cell_item(loc, 0)
						full_cell_array.append(loc)
					else:
						empty_cell_array.append(loc)
	
	if compute_type == 0:
		thread = Thread.new()
		thread.start(Callable(self, "_thread_function"),Thread.PRIORITY_HIGH)
	else:
		gc.shader_file = load("res://comp.glsl")
		gc._load_shader()
		
		var lim_buff = gc.rd.limit_get(RenderingDevice.LIMIT_MAX_UNIFORM_BUFFER_SIZE)
		
		var lim_wgc_x = gc.rd.limit_get(RenderingDevice.LIMIT_MAX_COMPUTE_WORKGROUP_COUNT_X)
		var lim_wgc_y = gc.rd.limit_get(RenderingDevice.LIMIT_MAX_COMPUTE_WORKGROUP_COUNT_Y)
		var lim_wgc_z = gc.rd.limit_get(RenderingDevice.LIMIT_MAX_COMPUTE_WORKGROUP_COUNT_Z)
		
		var lim_wgs_x = gc.rd.limit_get(RenderingDevice.LIMIT_MAX_COMPUTE_WORKGROUP_SIZE_X)
		var lim_wgs_y = gc.rd.limit_get(RenderingDevice.LIMIT_MAX_COMPUTE_WORKGROUP_SIZE_Y)
		var lim_wgs_z = gc.rd.limit_get(RenderingDevice.LIMIT_MAX_COMPUTE_WORKGROUP_SIZE_Z)
		
		print("Max workgroup counts: X-" + str(lim_wgc_x) + " Y-" + str(lim_wgc_y) + " Z-" + str(lim_wgc_z))
		print("Max workgroup sizes: X-" + str(lim_wgs_x) + " Y-" + str(lim_wgs_y) + " Z-" + str(lim_wgs_z))
		print("Max uniform buffer size: %s MB" % (lim_buff / 1000000))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global.stop:
		msh.material.albedo_color = stop_color
	else:
		msh.material.albedo_color = go_color
	
	if compute_type == 0:
		_cpu_powered()
	elif compute_type == 1:
		if not global.stop:
			_gpu_powered()
	
	just_resumed = global.stop


func _reset():
	pass


func _cpu_powered():
	var result = false
	if not thread.is_alive() and not global.stop and thread.is_started():
		result = thread.wait_to_finish()
		#done = false
	if result and not global.stop:
		time = 0.0
		thread.start(Callable(self, "_thread_function"))
		new_blocks = false
	if result and !new_blocks:# and not done:
		for e in result[2]:
			set_cell_item(e,-1)
		for f in result[1]:
			set_cell_item(f,0)
		full_cell_array = result[1]
		empty_cell_array = result[2]


func _gpu_powered():
	if tick:
		if not gpu_started:
			wgsize = bounds*2
			var num_slots: int = int(pow(wgsize, 3.0))
			
			var new_array: PackedFloat32Array = array_from_gm()
			var slot_bytes := new_array.to_byte_array()
			
			var output_array := PackedFloat32Array([])
			output_array.resize(num_slots)
			output_array.fill(0.0)
			var output_bytes := output_array.to_byte_array()
			
			var param_array := PackedFloat32Array([living_cell_lives_with_neighbors_min,
												living_cell_lives_with_neighbors_max,
												dead_cell_lives_with_neighbors])
			var param_bytes := param_array.to_byte_array()
			
			gc._add_buffer(0, 0, slot_bytes)
			gc._add_buffer(0, 1, output_bytes)
			gc._add_buffer(0, 2, param_bytes)
			
			gc._make_pipeline(Vector3i(wgsize, wgsize, wgsize), true)
			
			gc._submit()
			
			var mem = gc.rd.get_memory_usage(RenderingDevice.MEMORY_TOTAL)
			
			mem /= 1000000
			
			print("Memory usage: %s MB" % mem)
			
			gpu_started = true
			timer.start(min_time)
			tick = false
		else:
			gc._sync()
			
			var output_bytes := gc.output(0, 1)
			var output := output_bytes.to_float32_array()
			
			
			if not just_resumed:
				gm_from_array(output)
			
			var param_array := PackedFloat32Array([living_cell_lives_with_neighbors_min,
													living_cell_lives_with_neighbors_max,
													dead_cell_lives_with_neighbors])
			var param_bytes := param_array.to_byte_array()
			
			var new_array: PackedFloat32Array = array_from_gm()
			var new_array_bytes := new_array.to_byte_array()
			
			gc._update_buffer(new_array_bytes, 0, 0)
			gc._update_buffer(param_bytes, 0, 2)
			
			gc._make_pipeline(Vector3i(wgsize, wgsize, wgsize))
			
			gc._submit()
			timer.start(min_time)
			tick = false


func gm_from_array(arr: PackedFloat32Array):
	var idx = 0
	for x in range(-bounds,bounds):
		for y in range(-bounds,bounds):
			for z in range(-bounds,bounds):
				var loc = Vector3(x,y,z)
				if arr[idx] == 1.0:
					if get_cell_item(loc) == -1:
						set_cell_item(loc, 2)
					else:
						set_cell_item(loc, 0)
				else:
					set_cell_item(loc, -1)
				
				idx += 1


func array_from_gm():
	var result := PackedFloat32Array([])
	for x in range(-bounds,bounds):
		for y in range(-bounds,bounds):
			for z in range(-bounds,bounds):
				var loc = Vector3(x,y,z)
				var item = get_cell_item(loc)
				if item == 0 or item == 2:
					result.append(1.0)
				else:
					result.append(0.0)
	return result


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
					else:
						empties.append(loc)
	return ['done', fulls, empties]


func _exit_tree():
	if compute_type == 0:
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


func _on_node3d_build_new_block(loc):
	mutex.lock()
	var new_loc = local_to_map(loc)
	var hitbounds = bounds - 1
	new_loc.x = clamp(new_loc.x,-hitbounds-1,hitbounds)
	new_loc.y = clamp(new_loc.y,-hitbounds-1,hitbounds)
	new_loc.z = clamp(new_loc.z,-hitbounds-1,hitbounds)
	if new_loc not in full_cell_array:
		print('newblock')
		full_cell_array.append(new_loc)
		empty_cell_array.erase(new_loc)
		set_cell_item(new_loc,0)
	mutex.unlock()
	new_blocks = true


func _on_node3d_delete_block(loc):
	mutex.lock()
	var new_loc = local_to_map(loc)
	var hitbounds = bounds - 1
	new_loc.x = clamp(new_loc.x,-hitbounds-1,hitbounds)
	new_loc.y = clamp(new_loc.y,-hitbounds-1,hitbounds)
	new_loc.z = clamp(new_loc.z,-hitbounds-1,hitbounds)
	if new_loc not in empty_cell_array:
		print('deleteblock')
		full_cell_array.erase(new_loc)
		empty_cell_array.append(new_loc)
		set_cell_item(new_loc,-1)
	mutex.unlock()
	new_blocks = true


func clear_build_cursor():
	pass


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
			


func _on_timer_timeout():
	tick = true
