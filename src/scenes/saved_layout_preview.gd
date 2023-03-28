extends Panel

@onready var cells: PackedVector3Array
@onready var node_3d = $MarginContainer/HBoxContainer/SubViewportContainer/SubViewport/Node3D
@onready var title = $MarginContainer/HBoxContainer/Panel/MarginContainer/VBoxContainer/Title
@onready var desc = $MarginContainer/HBoxContainer/Panel/MarginContainer/VBoxContainer/Desc

var t_name: String
var t_desc: String

# Called when the node enters the scene tree for the first time.
func _ready():
	title.text = t_name
	desc.text = t_desc

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func SetName(value):
	pass
