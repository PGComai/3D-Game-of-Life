extends GridMap

signal mark_cell(cell_to_mark)
signal clear_cell(cell_to_clear)
signal send_bounds(b)

@export var living_cell_lives_with_neighbors_min: int = 2
@export var living_cell_lives_with_neighbors_max: int = 5
@export var dead_cell_lives_with_neighbors: int = 5
@export var bounds: int = 10
@export var min_time: float = 0.2
@export_enum('CPU','GPU') var compute_type: int = 0
@export var img2d: Image

@onready var comp = preload("res://comp.glsl")
@onready var testmesh = $testmesh

var counter = 0
var thread
var stop: bool = false
var build: bool = false
var go_color: Color = Color('f3836b')
var stop_color: Color = Color('bda837')
var msh = mesh_library.get_item_mesh(1)
var time: float = 0
var n3d
var full_cell_array: Array
var empty_cell_array: Array
var expanding_search_exclude: Array
var buildCursor: Vector3i
var done: bool

var rd: RenderingDevice
var imgTexArray: Array
var comp_frame_count: int = 0
var texture_read: RID
var texture_write: RID
var read_data: PackedByteArray
var write_data: PackedByteArray
var buffer: RID
var shader: RID
var uniform_set: RID
var pipeline: RID
var image_format := Image.FORMAT_RGBA8
var image_size: Vector2i

# Called when the node enters the scene tree for the first time.
func _ready():
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
	img2d = make_img2d_from_gm()
	testmesh.material_overlay.albedo_texture = ImageTexture.create_from_image(img2d)
	#print(img2d.get_size())
	if compute_type == 0:
		thread = Thread.new()
		# Third argument is optional userdata, it can be any variable.
		thread.start(Callable(self, "_thread_function"),Thread.PRIORITY_HIGH)
	else:
		rd = RenderingServer.create_local_rendering_device()
		if not rd:
			set_process(false)
			print("Compute shaders are not available")
			return
		
		# Create shader and pipeline
		var shader_spirv := comp.get_spirv()
		shader = rd.shader_create_from_spirv(shader_spirv)
		pipeline = rd.compute_pipeline_create(shader)

		var og_image := img2d
		og_image.convert(image_format)
		image_size = og_image.get_size()

		# Data for compute shaders has to come as an array of bytes
		# Initialize read data
		read_data = og_image.get_data()

		var tex_read_format := RDTextureFormat.new()
		tex_read_format.width = image_size.x
		tex_read_format.height = image_size.y
		tex_read_format.depth = 4
		tex_read_format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
		tex_read_format.usage_bits = (
			RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
			| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		)
		var tex_view := RDTextureView.new()
		texture_read = rd.texture_create(tex_read_format, tex_view, [read_data])

		# Create uniform set using the read texture
		var read_uniform := RDUniform.new()
		read_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		read_uniform.binding = 0
		read_uniform.add_id(texture_read)

		# Initialize write data
		write_data = PackedByteArray()
		write_data.resize(read_data.size())

		var tex_write_format := RDTextureFormat.new()
		tex_write_format.width = image_size.x
		tex_write_format.height = image_size.y
		tex_write_format.depth = 4
		tex_write_format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
		tex_write_format.usage_bits = (
			RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
			| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
			| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
		)
		texture_write = rd.texture_create(tex_write_format, tex_view, [write_data])

		# Create uniform set using the write texture
		var write_uniform := RDUniform.new()
		write_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		write_uniform.binding = 1
		write_uniform.add_id(texture_write)
		
		# Prepare our data. We use floats in the shader, so we need 32 bit.
		var input := PackedFloat32Array([living_cell_lives_with_neighbors_min,living_cell_lives_with_neighbors_max,dead_cell_lives_with_neighbors])
		var input_bytes := input.to_byte_array()

		# Create a storage buffer that can hold our float values.
		# Each float has 4 bytes (32 bit) so 10 x 4 = 40 bytes
		buffer = rd.storage_buffer_create(input_bytes.size(), input_bytes)
		
		# Create a uniform to assign the buffer to the rendering device
		var uniform := RDUniform.new()
		uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		uniform.binding = 2 # this needs to match the "binding" in our shader file
		uniform.add_id(buffer)

		uniform_set = rd.uniform_set_create([read_uniform, write_uniform, uniform], shader, 0)
		
#		var shader_file := load("res://comp.glsl")
#		var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
#		var shader := rd.shader_create_from_spirv(shader_spirv)
#
#		# Prepare our data. We use floats in the shader, so we need 32 bit.
#		var input_bytes := PackedByteArray(imgTexArray)
#		#var input_bytes := input.to_byte_array()
#
#		# Create a storage buffer that can hold our float values.
#		# Each float has 4 bytes (32 bit) so 10 x 4 = 40 bytes
#		var buffer := rd.storage_buffer_create(input_bytes.size(), input_bytes)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if compute_type == 0:
		_cpu_powered(delta)
	else:
		_gpu_powered()

func _cpu_powered(delta):
	if stop:
		msh.material.albedo_color = stop_color
	else:
		msh.material.albedo_color = go_color
	var result = false
	time += delta
	if not thread.is_alive() and not stop and thread.is_started() and time >= min_time:
		result = thread.wait_to_finish()
		#done = false
	if result and not stop:
		time = 0
		thread.start(Callable(self, "_thread_function"))
	if result:# and not done:
		for e in result[2]:
			set_cell_item(e,-1)
		for f in result[1]:
			set_cell_item(f,0)
		full_cell_array = result[1]
		empty_cell_array = result[2]
		#done = true
	if build:
		for e in empty_cell_array:
			if Vector3i(e) != buildCursor:
				set_cell_item(e,-1)
		for f in full_cell_array:
			if Vector3i(f) != buildCursor:
				set_cell_item(f,0)
		set_cell_item(buildCursor,2)
		print(buildCursor)

func _gpu_powered():
	if fmod(comp_frame_count, 5.0) == 0.0:
		var pf32a = PackedFloat32Array([living_cell_lives_with_neighbors_min,living_cell_lives_with_neighbors_max,dead_cell_lives_with_neighbors])
		var tba = pf32a.to_byte_array()

		# Create a storage buffer that can hold our float values.
		# Each float has 4 bytes (32 bit) so 10 x 4 = 40 bytes
		#buffer = rd.storage_buffer_create(input_bytes.size(), input_bytes)
		
		rd.buffer_update(buffer, 0, tba.size(), tba)
		
		rd.texture_update(texture_read, 0, read_data)
		# Start compute list to start recording our compute commands
		var compute_list := rd.compute_list_begin()
		# Bind the pipeline, this tells the GPU what shader to use
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
		# Binds the uniform set with the data we want to give our shader
		rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
		var wgsize = bounds*2
		rd.compute_list_dispatch(compute_list, wgsize, wgsize, wgsize)
		rd.compute_list_end()  # Tell the GPU we are done with this compute task
		rd.submit()  # Force the GPU to start our commands
		rd.sync()  # Force the CPU to wait for the GPU to finish with the recorded commands

		# Now we can grab our data from the texture
		read_data = rd.texture_get_data(texture_write, 0)
		var image := Image.create_from_data(image_size.x, image_size.y, false, image_format, read_data)
		testmesh.material_overlay.albedo_texture = ImageTexture.create_from_image(image)
		_make_gm_from_img2d(image)
	comp_frame_count += 1

func make_img2d_from_gm():
	# make long form image instead of deep image
	
	# y stays the same but x increases by 2*bounds(?) to represent new z slice
	var arrimg = Image.create(pow(2*bounds,2), 2*bounds, false, Image.FORMAT_RGBA8)
	var zidx = 0
	for z in range(-bounds,bounds):
		var z_offset = (2*bounds) * zidx
		for x in range(-bounds,bounds):
			for y in range(-bounds,bounds):
				var loc = Vector3(x,y,z)
				var item = get_cell_item(loc)
				if item == 0:
					# cell is full
					arrimg.set_pixelv(Vector2i(x+bounds+z_offset,y+bounds), Color.WHITE)
				elif item == -1:
					arrimg.set_pixelv(Vector2i(x+bounds+z_offset,y+bounds), Color.BLACK)
		zidx += 1
	return arrimg
	
func _make_gm_from_img2d(img: Image):
	# make long form image instead of deep image
	# y stays the same but x increases by 2*bounds(?) to represent new z slice
	var zidx = 0
	for z in range(-bounds,bounds):
		var z_offset = (2*bounds) * zidx
		for x in range(-bounds,bounds):
			for y in range(-bounds,bounds):
				var loc = Vector3(x,y,z)
				var imgloc = Vector2i(x+bounds+z_offset,y+bounds)
				var val = img.get_pixelv(imgloc)
				if val == Color.BLACK:
					set_cell_item(loc, -1)
				else:
					set_cell_item(loc, 0)
		zidx += 1

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
		
func _on_node3d_delete_block(loc):
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
		

#func _on_node3d_buildRay(loc):
#	var hit = local_to_map(loc)
#	var to_clear = get_used_cells_by_item(2)
#	var occupied = get_used_cells_by_item(0)
#	for tc in to_clear:
#		if tc in occupied or tc == hit:
#			pass
#		else:
#			set_cell_item(tc,-1)
#	var hitbounds = bounds - 1
#	hit.x = clamp(hit.x,-hitbounds,hitbounds)
#	hit.y = clamp(hit.y,-hitbounds,hitbounds)
#	hit.z = clamp(hit.z,-hitbounds,hitbounds)
#	buildCursor = hit
	
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
			
