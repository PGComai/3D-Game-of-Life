extends Node3D

@export var tex: Texture2D

# Called when the node enters the scene tree for the first time.
func _ready():
	var img = tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var imgarr = img.get_data()
	print(imgarr)
	var img2 = Image.create_from_data(10,10,false,Image.FORMAT_RGBA8,imgarr)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
