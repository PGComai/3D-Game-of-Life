extends Panel

@onready var cells: PackedVector3Array
@onready var node_3d = $MarginContainer/HBoxContainer/SubViewportContainer/SubViewport/Node3D
@onready var title = $MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/Title.text
@onready var desc = $MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/Desc.text

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
