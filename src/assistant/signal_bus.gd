extends Node


signal state_update_requested(new_state)

signal obs_state_requested
signal obs_state_reported(state)
signal obs_command_requested(command, data)