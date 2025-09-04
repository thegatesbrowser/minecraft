extends Resource
class_name CraftableLibrary

@export var craftable_array: Array[Blueprint]

var craftables: Dictionary = {}


func init_craftable():
	for craftable in craftable_array:
		craftables[craftable.Name] = craftable


func get_craftable(unique_name: StringName) -> Blueprint:
	return craftables[unique_name]
