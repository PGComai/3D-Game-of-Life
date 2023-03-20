extends Panel

signal save_confirmed(savename, description)

@onready var text_edit = $MarginContainer/VBoxContainer/TextEdit

var title: String
var desc: String

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_button_pressed():
	emit_signal('save_confirmed', title, desc)
	queue_free()

func _on_button_2_pressed():
	queue_free()

func _on_line_edit_text_changed(new_text):
	title = new_text

func _on_text_edit_text_changed():
	desc = text_edit.text
