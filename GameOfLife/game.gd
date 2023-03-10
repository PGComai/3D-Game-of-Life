extends Node3D

@onready var ch = $CamHinge
@onready var cm = $CamHinge/Camera3D
@onready var gh = $GridHolder
@onready var gg = preload("res://GameGrid.tscn")

var cpz: float
var roty: float
var rotx: float
var q_reset: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cpz = cm.position.z
	roty = ch.rotation.y
	rotx = ch.rotation.x

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		roty += event.relative.x * 0.001
		rotx += event.relative.y * 0.001
		rotx = clamp(rotx, -PI/4, PI/4)
		roty = clamp(roty, cm.rotation.y-PI/4, cm.rotation.y+PI/4)
	if event.is_action_pressed("reset"):
		q_reset = true
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# reset the game grid
	if q_reset and gh.get_child_count() > 0:
		gh.get_child(0).queue_free()
		q_reset = false
	if gh.get_child_count() == 0:
		var newgrid = gg.instantiate()
		gh.add_child(newgrid)
	# zoom and rotate
	if Input.is_action_just_released('zin'):
		cpz = cm.position.z - 10
	if Input.is_action_just_released('zout'):
		cpz = cm.position.z + 10
	cpz = clamp(cpz, 5, 100)
	cm.position.z = lerp(cm.position.z, cpz, 0.1)
	if !is_equal_approx(roty,0):
		ch.rotation.y = lerp_angle(ch.rotation.y, ch.rotation.y - roty, 0.05)
	if !is_equal_approx(rotx,0):
		ch.rotation.x = lerp_angle(ch.rotation.x, ch.rotation.x - rotx, 0.05)
	roty = lerp(roty, 0., 0.03)
	rotx = lerp(rotx, 0., 0.03)
