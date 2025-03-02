extends Resource
class_name CraftableLibrary

@export var craftable_array: Array[Craftable]

var craftables: Dictionary = {}


func init_craftable():
	for craftable in craftable_array:
		craftables[craftable.unique_name] = craftable


func get_craftable(unique_name: StringName) -> Craftable:
	return craftables[unique_name]
