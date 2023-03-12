extends Node3D

@onready var ch = $CamHinge
@onready var cm = $CamHinge/Camera3D
@onready var gh = $GridHolder
@onready var gg = preload("res://scenes/GameGrid.tscn")

var cpz: float
var roty: float
var rotx: float
var q_reset: bool = false
var rot: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	cpz = cm.position.z
	roty = ch.rotation.y
	rotx = ch.rotation.x

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if rot:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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
