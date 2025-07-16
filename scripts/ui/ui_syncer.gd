extends Node

@export var inventory_holder:HBoxContainer

var server_ui_info:Dictionary = {}
var opened_ui:Vector3 ## tells the server which ui is opened

func _ready() -> void:
	Globals.sync_add_metadata.connect(add_metadata)

@rpc("any_peer", "call_local")
func send_to_server(index: int, item_path: String, amount: int, parent: String, health:float, rot: int) -> void:
	if multiplayer.is_server():
		#print("openui ",opened_ui)
		if opened_ui == Vector3.ZERO: return
		if !server_ui_info.has(str(opened_ui)): return
		server_ui_info[str(opened_ui)].inventory[str(index)] = {
			"item_path":item_path,
			"amount":amount,
			"parent":parent,
			"health":health,
			"rot":rot
		}

func save() -> Dictionary:
	if multiplayer.is_server():
		var save_dict = {
			"server_ui_info":server_ui_info
		}
		return save_dict
	else:
		return {}

func add_metadata(pos:Vector3,metadata) -> void:
	sync_add_metadata.rpc_id(1,pos,metadata)
	
	
@rpc("any_peer","call_local") 
func sync_add_metadata(pos,metadata) -> void:
	var t = get_tree().get_first_node_in_group("VoxelTerrain") as VoxelTerrain
	t.get_voxel_tool().set_voxel_metadata(pos,metadata)
