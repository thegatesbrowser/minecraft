extends Resource
class_name ItemsLibrary

@export var items_array: Array[ItemBase]

var items: Dictionary = {}
var types:Array = []

func init_items():
	for item in items_array:
		items[item.unique_name] = item
		types.append(item.unique_name)

func get_item(unique_name: StringName) -> ItemBase:
	return items[unique_name]
