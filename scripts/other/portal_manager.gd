extends Node

@export var UI: Control

var server_info: Dictionary = {}


func _ready() -> void:
	#Globals.create_portal.connect(add_new_portal)
	#Globals.add_portal_url.connect(add_portal_url)
	Globals.enter_portal.connect(enter_portal)
	#Globals.remove_portal_data.connect(remove_portal_data)

func enter_portal(url:String):
	print("enter",url)
	if get_tree().has_method("send_command"):
		
		get_tree().send_command("open_gate", [url])

#func add_new_portal(id: Vector3) -> void:
	#send_to_server.rpc_id(1,id)
#
#
#func check_portal(id: Vector3) -> void:
	#server_check_portal.rpc_id(1,id)


#@rpc("any_peer","call_local")
#func send_to_server(id: Vector3, url: String = "https://thegates.io/worlds/devs/snap_games_studio/minecraft_world2.gate") -> void:
	#server_info[id] = {
		#"url": url
	#}
	#
#
#func add_portal_url(id: Vector3, url: String) -> void:
	#send_to_server.rpc_id(1,id,url)

#
#@rpc("any_peer","call_local")
#func server_check_portal(id: Vector3) -> void:
	#if server_info.has(id):
		#var sender = multiplayer.get_remote_sender_id()
		#give_client.rpc_id(sender,server_info[id])
#
#
#@rpc("any_peer","call_local")
#func give_client(info: Dictionary) -> void:
	#
	#print("taken client ",multiplayer.get_unique_id()," ", info)
	#
	#if get_tree().has_method("send_command"):
		#get_tree().send_command("open_gate", [info.url])
#
#
#@rpc("any_peer","call_local")
#func remove_portal_data(id: Vector3) -> void:
	#if server_info.has(id):
		#server_info.erase(id)
