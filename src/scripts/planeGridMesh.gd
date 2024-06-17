extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready():
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	var verts = PackedVector3Array()
	var indices = PackedInt32Array()

	var r = range(-4,5,2)
	var y = 0
	for x in r:
		for z in r:
			var vec = Vector3(x,y,z)
			verts.append(vec)
	for z in r:
		for x in r:
			var vec = Vector3(x,y,z)
			verts.append(vec)
	surface_array[Mesh.ARRAY_VERTEX] = verts
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, surface_array)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
