extends Control

signal save_requested
signal stop
signal go
signal build

@onready var save_layout_template = preload("res://resources/saved_layout.gd")
@onready var gg = preload("res://scenes/GameGrid.tscn")
@onready var save_popup = preload("res://scenes/save_popup.tscn")
@onready var all_saves = preload("res://resources/all_saves.tres")

@onready var ch = $PanelContainer/HBoxContainer/AspectRatioContainer/gameBG/SubViewportContainer/SubViewport/Node3D/CamHinge
@onready var cm = $PanelContainer/HBoxContainer/AspectRatioContainer/gameBG/SubViewportContainer/SubViewport/Node3D/CamHinge/Camera3D
@onready var gh = $PanelContainer/HBoxContainer/AspectRatioContainer/gameBG/SubViewportContainer/SubViewport/Node3D/GridHolder
@onready var slider1 = $PanelContainer/HBoxContainer/leftBG/MarginContainer/VBoxContainer/HBoxContainer/slider/VSlider1
@onready var label1 = $PanelContainer/HBoxContainer/leftBG/MarginContainer/VBoxContainer/HBoxContainer/slider/SliderVal1
@onready var slider2 = $PanelContainer/HBoxContainer/leftBG/MarginContainer/VBoxContainer/HBoxContainer/slider2/VSlider2
@onready var label2 = $PanelContainer/HBoxContainer/leftBG/MarginContainer/VBoxContainer/HBoxContainer/slider2/SliderVal2
@onready var slider3 = $PanelContainer/HBoxContainer/leftBG/MarginContainer/VBoxContainer/HBoxContainer/slider3/VSlider3
@onready var label3 = $PanelContainer/HBoxContainer/leftBG/MarginContainer/VBoxContainer/HBoxContainer/slider3/SliderVal3
@onready var WorldSize = $PanelContainer/HBoxContainer/leftBG/MarginContainer/VBoxContainer/WorldSize
@onready var BoundSlider = $PanelContainer/HBoxContainer/leftBG/MarginContainer/VBoxContainer/boundSlider
@onready var subv = $PanelContainer/HBoxContainer/AspectRatioContainer/gameBG/SubViewportContainer/SubViewport
@onready var sun = $PanelContainer/HBoxContainer/AspectRatioContainer/gameBG/SubViewportContainer/SubViewport/Node3D/DirectionalLight3D
@onready var env = $PanelContainer/HBoxContainer/AspectRatioContainer/gameBG/SubViewportContainer/SubViewport/Node3D/WorldEnvironment
@onready var tick = $PanelContainer/HBoxContainer/leftBG/MarginContainer/VBoxContainer/tickslider
@onready var tickLabel = $PanelContainer/HBoxContainer/leftBG/MarginContainer/VBoxContainer/TickTime
@onready var selection = $PanelContainer/HBoxContainer/AspectRatioContainer/gameBG/SubViewportContainer/SubViewport/Node3D/SelectionGrid
@onready var saveButton = $PanelContainer/HBoxContainer/rightBG/MarginContainer/VBoxContainer/SaveButton
@onready var aspect_ratio_container = $PanelContainer/HBoxContainer/AspectRatioContainer
@onready var save_list = $PanelContainer/HBoxContainer/rightBG/MarginContainer/VBoxContainer/ScrollContainer/SaveList
@onready var node_3d = $PanelContainer/HBoxContainer/AspectRatioContainer/gameBG/SubViewportContainer/SubViewport/Node3D
@onready var compute = $PanelContainer/HBoxContainer/leftBG/MarginContainer/VBoxContainer/cpu_gpu_box/compute

var gm
var cpz: float
var roty: float
var rotx: float
var q_reset: bool = false
var rot: bool = false
var slider1val: int
var slider2val: int
var slider3val: int
var looking: bool = false
var bound: int
var sim_tick: float
var selecting: bool = false
var cells_to_save: Array[Vector3i]
var compute_mode: int

var saver = ResourceSaver


# Called when the node enters the scene tree for the first time.
func _ready():
	selection.save_cells.connect(_on_selection_save_cells)
	selection.selected.connect(_on_selection_selected)
	selection.not_selected.connect(_on_selection_not_selected)
	cpz = cm.position.z
	roty = ch.rotation.y
	rotx = ch.rotation.x 
	if get_node("PanelContainer/HBoxContainer/AspectRatioContainer/gameBG/SubViewportContainer/SubViewport/Node3D/GridHolder").get_child_count() > 0:
		gm = $PanelContainer/HBoxContainer/AspectRatioContainer/gameBG/SubViewportContainer/SubViewport/Node3D/GridHolder.get_child(0)
		slider1.set_value_no_signal(gm.living_cell_lives_with_neighbors_min)
		label1.text = str(gm.living_cell_lives_with_neighbors_min)
		slider1val = gm.living_cell_lives_with_neighbors_min
		slider2.set_value_no_signal(gm.living_cell_lives_with_neighbors_max)
		label2.text = str(gm.living_cell_lives_with_neighbors_max)
		slider2val = gm.living_cell_lives_with_neighbors_max
		slider3.set_value_no_signal(gm.dead_cell_lives_with_neighbors)
		label3.text = str(gm.dead_cell_lives_with_neighbors)
		slider3val = gm.dead_cell_lives_with_neighbors
		tick.set_value_no_signal(gm.min_time)
		tickLabel.text = 'Minimum Simulation Tick: ' + str(gm.min_time) + 's'
		bound = gm.bounds
		BoundSlider.set_value_no_signal(bound)
		var boundstr = str(bound*2)
		WorldSize.text = 'World Size: ' + boundstr + 'x' + boundstr
		compute_mode = gm.compute_type
		if compute_mode == 0:
			compute.set_pressed_no_signal(false)
		else:
			compute.set_pressed_no_signal(true)


func _unhandled_input(event):
	if event is InputEventMouseMotion and rot and looking and not node_3d.y_adjust:
		roty += event.relative.x * 0.001
		rotx += event.relative.y * 0.001
		rotx = clamp(rotx, -PI/4, PI/4)
		roty = clamp(roty, cm.rotation.y-PI/4, cm.rotation.y+PI/4)
	if event.is_action_pressed("stop") and gh.get_child_count() > 0:
		node_3d.y_adjust = false
		if gm.stop:
			emit_signal('go')
			gm.stop = false
			gm.build = false
		else:
			emit_signal('stop')
			gm.stop = true
	if event.is_action_pressed("build") and gh.get_child_count() > 0:
		node_3d.y_adjust = false
		if gm.stop:
			emit_signal("build")
			gm.build = !gm.build
		else:
			emit_signal('stop')
			gm.stop = true
			emit_signal("build")
			gm.build = !gm.build
	if event.is_action_pressed("reset"):
		node_3d.y_adjust = false
		q_reset = true
	if looking:
		if event is InputEventPanGesture:
			cpz = cm.position.y - event.delta.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("middle_click") and looking:
		rot = true
	if Input.is_action_just_released("middle_click"):
		rot = false
	if rot:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# reset the game grid
	if q_reset and gh.get_child_count() > 0:
		gh.get_child(0).queue_free()
	if gh.get_child_count() == 0:
		# make new grid
		var newgrid = gg.instantiate()
		newgrid.bounds = bound
		newgrid.living_cell_lives_with_neighbors_min = slider1val
		newgrid.living_cell_lives_with_neighbors_max = slider2val
		newgrid.dead_cell_lives_with_neighbors = slider3val
		newgrid.min_time = sim_tick
		newgrid.compute_type = compute_mode
		gh.add_child(newgrid)
		gm = gh.get_child(0)
		# set new grid variables
		q_reset = false
	label1.text = str(gm.living_cell_lives_with_neighbors_min)
	label2.text = str(gm.living_cell_lives_with_neighbors_max)
	label3.text = str(gm.dead_cell_lives_with_neighbors)
	var boundstr = str(bound*2)
	WorldSize.text = 'World Size: ' + boundstr + 'x' + boundstr
	cam()
	saveButton.disabled = !selecting


func cam():
	# zoom and rotate
	if looking:
		if Input.is_action_just_released('zin'):
			cpz = cm.position.z - 10
		if Input.is_action_just_released('zout'):
			cpz = cm.position.z + 10
	cpz = clamp(cpz, 5, 250)
	cm.position.z = lerp(cm.position.z, cpz, 0.1)
	if !is_equal_approx(roty,0):
		ch.rotation.y = lerp_angle(ch.rotation.y, ch.rotation.y - roty, 0.05)
	if !is_equal_approx(rotx,0):
		ch.rotation.x = lerp_angle(ch.rotation.x, ch.rotation.x - rotx, 0.05)
	ch.rotation.x = clamp(ch.rotation.x, -PI/2, PI/2)
	roty = lerp(roty, 0.0, 0.03)
	rotx = lerp(rotx, 0.0, 0.03)


func _on_v_slider_1_value_changed(value):
	gm.living_cell_lives_with_neighbors_min = value
	slider1val = value
	if slider1val > slider2val:
		gm.living_cell_lives_with_neighbors_max = slider1val
		slider1.share(slider2)
		slider2val = slider1val
		slider1.unshare()


func _on_v_slider_2_value_changed(value):
	gm.living_cell_lives_with_neighbors_max = value
	slider2val = value
	if slider1val > slider2val:
		gm.living_cell_lives_with_neighbors_min = slider2val
		slider2.share(slider1)
		slider1val = slider2val
		slider2.unshare()


func _on_v_slider_3_value_changed(value):
	gm.dead_cell_lives_with_neighbors = value
	slider3val = value


func _on_button_pressed():
	q_reset = true


func _on_button_2_pressed():
	get_tree().quit()


func _on_aspect_ratio_container_mouse_entered():
	looking = true


func _on_aspect_ratio_container_mouse_exited():
	looking = false


func _on_bound_slider_value_changed(value):
	bound = value


func _on_scaling_item_selected(index):
	var _scale: float
	if index == 0:
		_scale = 1.25
	elif index == 2:
		_scale = 0.75
	else:
		_scale = 1.0
	subv.scaling_3d_scale = _scale


func _on_aa_item_selected(index):
	if index == 1:
		subv.msaa_3d = 2
	elif index == 0:
		subv.msaa_3d = 4
	else:
		subv.msaa_3d = 0


func _on_shadow_item_selected(index):
	if index == 0:
		sun.shadow_enabled = true
		sun.directional_shadow_mode = 2
		sun.shadow_bias = 0.1
	elif index == 1:
		sun.shadow_enabled = true
		sun.directional_shadow_mode = 0
		sun.shadow_bias = 0.02
	else:
		sun.shadow_enabled = false


func _on_lighting_item_selected(index):
	if index == 0:
		env.environment.ssil_enabled = true
	else:
		env.environment.ssil_enabled = false


func _on_tickslider_value_changed(value):
	gm.min_time = value
	tickLabel.text = 'Minimum Simulation Tick: ' + str(value) + 's'
	sim_tick = value


func _on_selection_save_cells(cells):
	# this is where the saving starts
	cells_to_save = cells
	var pop = save_popup.instantiate()
	pop.save_confirmed.connect(_on_pop_save_confirmed)
	aspect_ratio_container.add_child(pop)


func _on_pop_save_confirmed(title: String, desc: String):
	# this is where the saving continues
	print(cells_to_save)
	var info = make_map_save_info(cells_to_save)
	print(info)
	var new_layout = save_layout_template.new()
	new_layout.cells = cells_to_save
	new_layout.name = title
	new_layout.description = desc
	saver.save(new_layout, "res://saved_files/%s.tres" % title, 0)
	var saved_resource = load("res://saved_files/%s.tres" % title)
	all_saves.saved_layouts.append(saved_resource)
	saver.save(all_saves, all_saves.resource_path, 0)
	save_list.refresh()


func _on_selection_selected():
	selecting = true


func _on_selection_not_selected():
	selecting = false


func _on_save_button_pressed():
	emit_signal("save_requested")


func make_map_save_info(points: Array[Vector3i]):
	var tx = 0
	var ty = 0
	var tz = 0
	for p in points:
		tx += p.x
		ty += p.y
		tz += p.z
	var arr_len = len(points)
	var center = Vector3i(tx/arr_len, ty/arr_len, tz/arr_len)
	var dists = []
	for p in points:
		dists.append(Vector3(p).distance_squared_to(Vector3(center)))
	var max_dist = sqrt(dists.max())
	return [center,max_dist]


func _on_compute_toggled(button_pressed):
	if button_pressed:
		compute_mode = 1
	else:
		compute_mode = 0


func _on_draw_mode_item_selected(index):
	if index == 0:
		subv.debug_draw = SubViewport.DEBUG_DRAW_DISABLED
	elif index == 1:
		subv.debug_draw = SubViewport.DEBUG_DRAW_OVERDRAW
	else:
		pass
