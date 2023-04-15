extends Node3D

@export var img: Image

# Called when the node enters the scene tree for the first time.
func _ready():
	var imgarr = img.get_data()
	print(imgarr)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
