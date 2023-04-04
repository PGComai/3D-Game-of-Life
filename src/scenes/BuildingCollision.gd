extends CollisionShape3D

@onready var cam = $"../../CamHinge/Camera3D"
@onready var grid_holder = $"../../GridHolder"
@onready var buildingMesh = $"../buildingGridMesh"
@onready var node_3d = $"../.."
@onready var plane_grid_map = $"../PlaneGridMap"

var bounds: int
var face: String
var p4 = PI/4

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	#self.shape.size = Vector3(bounds,1,bounds)
#	plane_grid_map.rotation = Vector3(PI/2,0,0)
#	plane_grid_map.position = Vector3(0,1,0)

func check_cam_angles():
	var facing: Vector3 = cam.get_camera_transform().basis.z
	var angUP = facing.angle_to(Vector3.UP)
	var angFORWARD = facing.angle_to(Vector3.FORWARD)
	var angBACK = facing.angle_to(Vector3.BACK)
	var angLEFT = facing.angle_to(Vector3.LEFT)
	var angRIGHT = facing.angle_to(Vector3.RIGHT)
	var angDOWN = facing.angle_to(Vector3.DOWN)
	if angDOWN <= p4:
		self.shape.size = Vector3(bounds,1,bounds)
		plane_grid_map.rotation = Vector3(PI/2,0,0)
		plane_grid_map.position = Vector3(0,3,0)
		#print('looking up')
	elif angUP <= p4:
		self.shape.size = Vector3(bounds,1,bounds)
		plane_grid_map.rotation = Vector3(PI/2,0,0)
		plane_grid_map.position = Vector3(0,1,0)
		#print('looking down')
	elif angFORWARD <= p4:
		self.shape.size = Vector3(bounds,bounds,1)
		plane_grid_map.rotation = Vector3(0,0,0)
		plane_grid_map.position = Vector3(0,0,1)
		#print('looking back')
	elif angBACK <= p4:
		self.shape.size = Vector3(bounds,bounds,1)
		plane_grid_map.rotation = Vector3(0,0,0)
		plane_grid_map.position = Vector3(0,0,-1)
		#print('looking forward')
	elif angLEFT <= p4:
		self.shape.size = Vector3(1,bounds,bounds)
		plane_grid_map.rotation = Vector3(0,PI/2,0)
		plane_grid_map.position = Vector3(1,0,0)
		#print('looking right')
	elif angRIGHT <= p4:
		self.shape.size = Vector3(1,bounds,bounds)
		plane_grid_map.rotation = Vector3(0,PI/2,0)
		plane_grid_map.position = Vector3(-1,0,0)
		#print('looking left')

