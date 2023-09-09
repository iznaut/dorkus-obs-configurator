extends Resource
class_name AssistState


@export_category("Notification")
@export var message : String
@export var timeout : float = 2

@export_category("Animation")
@export var frames : Array[Texture2D]
@export var delay : float = 0.5


func has_frames() -> bool:
    return frames.size() > 0


func is_animated() -> bool:
    return frames.size() > 1