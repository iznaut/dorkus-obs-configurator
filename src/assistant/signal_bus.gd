extends Node


signal state_updated(new_state)
signal config_setting_requested(var_name)
signal config_setting_updated(var_name, new_value)

signal obs_command_requested(command, data)