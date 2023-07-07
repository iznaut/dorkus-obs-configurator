@tool
extends Control


signal button_pressed(label : String)

# export vars are visible in editor so you can set them per node instance
@export var label_string : String = "Placeholder"			
@export var icon_texture : Texture2D

# onready vars are good for getting references to nodes (cleaner than doing this in _ready)
@onready var label : Label = $Label
@onready var button : TextureButton = $TextureButton


func _ready():
	label.text = label_string

	# ugly way of getting a node
	button.get_node("TextureRect").texture = icon_texture


# just forwarding this with a custom signal
func _on_texture_button_pressed():
	button_pressed.emit(label_string)
