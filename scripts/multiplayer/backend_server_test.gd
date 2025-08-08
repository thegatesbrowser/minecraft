extends Node

var peer = WebSocketMultiplayerPeer.new()
var users = {}
var lobbies = {}
var dao = DAO.new()
var Characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
@export var hostPort = 8819

var cryptoUtil = UserCrypto.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	if "--server" in OS.get_cmdline_args():
		print("hosting on " + str(hostPort))
		peer.create_server(hostPort)
		
	peer.connect("peer_connected", peer_connected)
	peer.connect("peer_disconnected", peer_disconnected)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			#print(data)
			
			if data.message ==  Util.Message.lobby:
				JoinLobby(data)
			
			# legacy test server code left unused; login/createUser removed
				
			if data.message ==  Util.Message.offer || data.message ==  Util.Message.answer || data.message ==  Util.Message.candidate:
				print("source id is " + str(data.orgPeer))
				sendToPlayer(data.peer, data)
				
			if data.message ==  Util.Message.removeLobby:
				if lobbies.has(data.lobbyID):
					lobbies.erase(data.lobbyID)


func peer_connected(id):
	print("Peer Connected: " + str(id))
	users[id] = {
		"id" : id,
		"message" :  Util.Message.id
	}
	peer.get_peer(id).put_packet(JSON.stringify(users[id]).to_utf8_buffer())


func peer_disconnected(id):
	users.erase(id)


func JoinLobby(user):
	var _result = ""
	if user.lobbyValue == "":
		user.lobbyValue = generateRandomString()
		lobbies[user.lobbyValue] = Lobby.new(user.id)
		print(user.lobbyValue)
	var _player = lobbies[user.lobbyValue].AddPlayer(user.id, user.client_id)
	
	for p in lobbies[user.lobbyValue].Players:
		
		var data = {
			"message" :  Util.Message.userConnected,
			"id" : user.id
		}
		sendToPlayer(p, data)
		
		var data2 = {
			"message" :  Util.Message.userConnected,
			"id" : p
		}
		sendToPlayer(user.id, data2)
		
		var lobbyInfo = {
			"message" :  Util.Message.lobby,
			"players" : JSON.stringify(lobbies[user.lobbyValue].Players),
			"host" : lobbies[user.lobbyValue].HostID,
			"lobbyValue" : user.lobbyValue
		}
		sendToPlayer(p, lobbyInfo)
		
		
	
	var _data = {
		"message" :  Util.Message.userConnected,
		"id" : user.id,
		"host" : lobbies[user.lobbyValue].HostID,
		"player" : lobbies[user.lobbyValue].Players[user.id],
		"lobbyValue" : user.lobbyValue
	}
    
	sendToPlayer(user.id, _data)


func update(data):
	dao.change_data(data.data.client_id, data.data.change_name, data.data.change)

func get_player_data(data):
	var userData = dao.GetUserFromDB(data.data.client_id)
	var returnData = {
		"client_id" : userData.client_id,
		"id" : userData.id,
		"message" : Util.Message.playerinfo,
		"health" : userData.health,
		"Position_x": userData.Position_x,
		"Position_y": userData.Position_y,
		"Position_z": userData.Position_z,
		"Inventory": userData.Inventory,
		"Hotbar": userData.Hotbar, ## add stuff like player pos etc
	}
	peer.get_peer(data.peer).put_packet(JSON.stringify(returnData).to_utf8_buffer())

## removed login/createUser from test server
func sendToPlayer(userId, data):
	peer.get_peer(userId).put_packet(JSON.stringify(data).to_utf8_buffer())
	
func generateRandomString():
	var result = ""
	for i in range(32):
		var index = randi() % Characters.length()
		result += Characters[index]
	return result

func startServer():
	peer.create_server(8915)
	print("Started Server")

func _on_start_server_button_down():
	startServer()
	pass # Replace with function body.


func _on_button_2_button_down():
	var message = {
		"message" :  Util.Message.id,
		"data" : "test"
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass # Replace with function body.
