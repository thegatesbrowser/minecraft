extends Node

class_name State

signal Transitioned(state, new_state_name, data)

func Enter(data:Dictionary):
	pass
	
func Exit():
	pass
	
func Update(delta: float):
	pass
	
func Physics_Update(delta: float) -> void:
	pass
