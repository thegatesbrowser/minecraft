extends Node

var server_info := {}

@export var UI: Control


func _ready() -> void:
	Globals.create_portal.connect(add_new_portal)
	Globals.add_portal_url.connect(add_portal_url)
	Globals.enter_portal.connect(check_portal)


func add_new_portal(id:Vector3) -> void:
	send_to_server.rpc_id(1,id)


func check_portal(id:Vector3) -> void:
	server_check_portal.rpc_id(1,id)


@rpc("any_peer","call_local")
func send_to_server(id:Vector3,url := "https://thegates.io/worlds/world.gate") -> void:
	server_info[id] = {
		"url": url
	}
	
	#print(server_info[id])


func add_portal_url(id:Vector3,url:String) -> void:
	send_to_server.rpc_id(1,id,url)


@rpc("any_peer","call_local")
func server_check_portal(id:Vector3) -> void:
	if server_info.has(id):
		var sender = multiplayer.get_remote_sender_id()
		give_client.rpc_id(sender,server_info[id])
		
	
@rpc("any_peer","call_local")
func give_client(info:Dictionary) -> void:
	
	print("taken client ",multiplayer.get_unique_id()," ", info)
	
	if get_tree().has_method("send_command"):
		get_tree().send_command("open_gate", [info.url])
