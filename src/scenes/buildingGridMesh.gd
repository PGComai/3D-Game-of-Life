extends MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready():
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	var verts = PackedVector3Array()

	var r = range(-6,7,2)
	for x in r:
		for y in r:
			for z in r:
				var vec = Vector3(x,y,z)
				if vec == Vector3.ZERO or vec.distance_squared_to(Vector3.ZERO) > 50:
					pass
				else:
					verts.append(vec)

	surface_array[Mesh.ARRAY_VERTEX] = verts
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, surface_array)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
