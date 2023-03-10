extends Control

@onready var ch = $SubViewportContainer/SubViewport/Node3D/CamHinge
@onready var cm = $SubViewportContainer/SubViewport/Node3D/CamHinge/Camera3D
@onready var gh = $SubViewportContainer/SubViewport/Node3D/GridHolder
@onready var gg = preload("res://GameGrid.tscn")
@onready var slider1 = $leftBG/VBoxContainer/HBoxContainer/slider/VSlider1
@onready var label1 = $leftBG/VBoxContainer/HBoxContainer/slider/Label1

var gm

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
	if get_node("SubViewportContainer/SubViewport/Node3D/GridHolder").get_child_count() > 0:
		gm = $SubViewportContainer/SubViewport/Node3D/GridHolder.get_child(0)
		slider1.set_value_no_signal(gm.living_cell_lives_with_neighbors_min)
		label1.text = str(gm.living_cell_lives_with_neighbors_min)

func _input(event):
	if event is InputEventMouseMotion and rot:
		roty += event.relative.x * 0.001
		rotx += event.relative.y * 0.001
		rotx = clamp(rotx, -PI/4, PI/4)
		roty = clamp(roty, cm.rotation.y-PI/4, cm.rotation.y+PI/4)
	if event.is_action_pressed("middle_click"):
		rot = true
		print('rot')
	if event.is_action_released("middle_click"):
		rot = false
	if event.is_action_pressed("stop") and gh.get_child_count() > 0:
		if gm.stop:
			gm.stop = false
		else:
			gm.stop = true
	if event.is_action_pressed("reset"):
		q_reset = true
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if rot:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# reset the game grid
	if q_reset and gh.get_child_count() > 0:
		gh.get_child(0).queue_free()
	if gh.get_child_count() == 0:
		var newgrid = gg.instantiate()
		gh.add_child(newgrid)
		gm = gh.get_child(0)
		slider1.set_value_no_signal(gm.living_cell_lives_with_neighbors_min)
		q_reset = false
	label1.text = str(gm.living_cell_lives_with_neighbors_min)
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

func _on_v_slider_1_value_changed(value):
	gm.living_cell_lives_with_neighbors_min = value
