extends Node

signal username_result(result:bool)

var username:String = "davo"

var saved_data := {} ## username key

@rpc("any_peer","call_local")
func check_server_has_user(username:String,id:int) -> void:
	if saved_data.has(username):
		
		
		client_has_user.rpc_id(multiplayer.get_remote_sender_id(),true)
	else:
		
		saved_data[username] = {
			"player_data": {
				"id":"",
			}
		}
		
		print(saved_data, multiplayer.get_peers())
		
		client_has_user.rpc_id(multiplayer.get_remote_sender_id(),false)
		
@rpc("any_peer","call_local")
func client_has_user(result:bool):
	username_result.emit(result)
	

func save(caller_id:int):
	if not Connection.is_server(): return
	
	var player = get_node("/root/Main").find_child(str(caller_id))
