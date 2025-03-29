extends Node

enum Message{
	id,
	join,
	userConnected,
	userDisconnected,
	lobby,
	candidate,
	offer,
	answer,
	checkIn,
	serverLobbyInfo,
	removeLobby,
	createUser,
	loginUser ,
	playerinfo,
	failedToLogin,
	update
}

var peer = WebSocketMultiplayerPeer.new()
var users = {}
var lobbies = {}
var dao = DAO.new()
var Characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
@export var hostPort = 8915

var cryptoUtil = UserCrypto.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	if "--server" in OS.get_cmdline_user_args():
		print("hosting on " + str(hostPort))
		startServer()
		
	peer.connect("peer_connected", peer_connected)
	peer.connect("peer_disconnected", peer_disconnected)
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			print(data)
			
			if data.message == Message.update:
				update(data)
				
			if data.message == Message.loginUser:
				login(data)
				
			if data.message == Message.createUser:
				createUser(data)
				
			if data.message ==  Message.offer || data.message == Message.answer || data.message ==  Message.candidate:
				print("source id is " + str(data.orgPeer))
				sendToPlayer(data.peer, data)
				

func peer_connected(id):
	print("Backend Peer Connected: " + str(id))
	users[id] = {
		"id" : id,
		"message" :  Message.id
	}
	peer.get_peer(id).put_packet(JSON.stringify(users[id]).to_utf8_buffer())
	pass
	
func peer_disconnected(id):
	users.erase(id)
	pass
	
func update(data):
	dao.change_data(data.data.name)
	
func createUser(data):
	var salt = cryptoUtil.GenerateSalt()
	var hashedPassword = cryptoUtil.HashPassword(data.data.password, salt)
	dao.InsertUserData(data.data.username, hashedPassword, salt)
	login(data)
	
func login(data):
	var userData = dao.GetUserFromDB(data.data.username)
	if(userData.hashedPassword == cryptoUtil.HashPassword(data.data.password, userData.salt)):
		var returnData = {
			"username" : userData.name,
			"id" : userData.id,
			"message" : Message.playerinfo,
			"health" : userData.health ## add stuff like player pos etc
		}
		peer.get_peer(data.peer).put_packet(JSON.stringify(returnData).to_utf8_buffer())
	else:
		var returnData ={
			"message" :Message.failedToLogin,
			"text" : "Failed to login invalid username or password"
		}
		peer.get_peer(data.peer).put_packet(JSON.stringify(returnData).to_utf8_buffer())
		
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
		"message" :  Message.id,
		"data" : "test"
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass # Replace with function body.
