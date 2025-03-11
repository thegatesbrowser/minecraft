extends Node

@export var inventory_holder:HBoxContainer

var server_ui_info:Dictionary = {}

var opened_ui:Vector3 ## tells the server which ui is opened


func _ready() -> void:
	Globals.remove_ui.connect(remove_ui)
	Globals.open_inventory.connect(open_ui)
	Globals.new_ui.connect(new_ui)
	Globals.sync_ui_change.connect(ui_updated)


func new_ui(position,scene_path):
	server_make_ui.rpc_id(1,position,scene_path)


func open_ui(position:Vector3):
	check_server.rpc_id(1,position)
	Opened_ui.rpc_id(1,position)


func ui_updated(index: int, item_path: String, amount: int,parent:String):
	send_to_server.rpc(index,item_path,amount,parent)

@rpc("any_peer","call_local")
func send_to_server(index: int, item_path: String, amount: int, parent:String):
	if multiplayer.is_server():
		if opened_ui == Vector3.ZERO: return
		if !server_ui_info.has(opened_ui): return
		server_ui_info[opened_ui].inventory[index] = {
			"item_path":item_path,
			"amount":amount,
			"parent":parent
		}
		#print(server_ui_info)
		
@rpc("any_peer","call_local")
func server_make_ui(position,scene_path):
	server_ui_info[position] = {
		"scene":scene_path,
		"inventory": {}
	}

@rpc("any_peer",'call_local')
func check_server(position):
	if !server_ui_info.has(position): return
	var server_data = server_ui_info[position]
	give_clients.rpc_id(multiplayer.get_remote_sender_id(),server_data)
	
@rpc("any_peer","call_local")
func give_clients(server_data):
	var ui = load(server_data.scene).instantiate()
	inventory_holder.add_child(ui)
	ui.open(server_data.inventory)
				
@rpc("any_peer","call_local")
func Opened_ui(id: Vector3):
	## gives the id to the server to use
	opened_ui = id

@rpc("any_peer","call_local")
func remove_ui(id: Vector3) -> void:
	server_ui_info.erase(id)
