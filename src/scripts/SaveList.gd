extends VBoxContainer

@onready var preview = preload("res://scenes/saved_layout_preview.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	refresh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func refresh():
	for kid in get_children():
		kid.queue_free()
	var saved_resources = load("res://resources/all_saves.tres")
	for res in saved_resources.saved_layouts:
		var loaded_resource = load(res.resource_path)
		var new_preview = preview.instantiate()
		new_preview.cells = loaded_resource.cells
		new_preview.t_name = loaded_resource.name
		new_preview.t_desc = loaded_resource.description
		add_child(new_preview)
