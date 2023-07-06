@tool
extends Control

# export vars are visible in editor so you can set them per node instance
@export var label_string : String = "Placeholder"
			
@export var icon_texture : Texture2D

# onready vars are good for getting references to nodes (cleaner than doing this in _ready)
@onready var label : Label = $Label
@onready var button : TextureButton = $TextureButton


func _ready():
	label.text = label_string