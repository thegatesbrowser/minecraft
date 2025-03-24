extends StaticBody3D
class_name Dropped_Item

var Item: ItemBase
var amount:int

func collect():
	Globals.spawn_item_inventory.emit(Item,amount)
	sync_delete.rpc_id(1)

@rpc("any_peer","call_local")
func sync_delete():
	queue_free()
