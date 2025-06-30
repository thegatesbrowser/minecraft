extends Node

## server side
func has_Item(path:String) -> bool:
	var OK = load(path)
	if OK == null:
		return false
	else:
		return true
		
func create_item(path:String,resource_data:Dictionary):
	var item:ItemBase = dict_to_inst(resource_data)
	
	ResourceSaver.save(item,path)
