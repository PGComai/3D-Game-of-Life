@tool
extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready():
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	var verts = PackedVector3Array()
	var indices = PackedInt32Array()

	verts.append(Vector3(-1,-1,0))
	verts.append(Vector3(-1,1,0))
	verts.append(Vector3(1,1,0))
	verts.append(Vector3(1,-1,0))
	
	indices.append(0)
	indices.append(1)
	indices.append(2)
	indices.append(3)
	indices.append(0)

	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, surface_array)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
