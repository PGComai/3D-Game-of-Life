extends AudioStreamPlayer

var ok: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_v_slider_1_value_changed(value):
	play()

func _on_v_slider_2_value_changed(value):
	play()

func _on_v_slider_3_value_changed(value):
	play()
