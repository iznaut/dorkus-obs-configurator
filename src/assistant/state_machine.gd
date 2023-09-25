extends Node


enum {
	IDLE,
	RECORDING,
	NOTIFICATION,
	LOADING,
	MENU_OPENED,
}

const STATE_TO_ANIM := {
	IDLE: "idle",
	RECORDING: "recording",
	NOTIFICATION: "speaking",
	LOADING: "writing",
	MENU_OPENED: "crouch",
}
const DEFAULT_NOTIFICATION_TIME : float = 2.0

signal state_updated(state)
signal notification_updated(message, duration)
