extends Resource
class_name AssistState


enum AppState {
    IDLE,
    OBS_DOWNLOADING,
    OBS_DOWNLOADED,
    OBS_CONNECTED,
    OBS_DISCONNECTED,
    OBS_RECORDING_STARTED,
    OBS_RECORDING_STOPPED,
    OBS_REPLAY_SAVED,
    UNREAL_CONNECTED,
    UNREAL_DISCONNECTED,
    FRAMEIO_UPLOADING,
    FRAMEIO_UPLOADED,
}

@export var app_state : AppState
@export var message : String
@export var frames : Array[Texture2D]
@export var idle_on_timeout : bool