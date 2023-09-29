extends Control


@onready var anim_sprite := $AnimatedSprite2D


func _ready():
	StateMachine.state_updated.connect(_on_state_updated)


func _on_state_updated(new_state_id : int):

	if new_state_id == StateMachine.IDLE and OBSHelper.is_recording:
		new_state_id = StateMachine.RECORDING
	anim_sprite.animation = StateMachine.STATE_TO_ANIM[new_state_id]

	print("new state: %s" % anim_sprite.animation)
	
	# TODO - dynamic sizing of window to keep precious clickable space?
	# get_window().size = anim_sprite.sprite_frames.get_frame_texture(anim_sprite.animation, 0).get_size() * 0.1
