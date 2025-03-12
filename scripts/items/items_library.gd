extends Resource
class_name ItemsLibrary

@export var items_array: Array[ItemBase]

var items: Dictionary = {}

func init_items():
	for item in items_array:
		items[item.unique_name] = item

func get_item(unique_name: StringName) -> ItemBase:	
	return items[unique_name]
