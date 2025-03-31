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
	if "--server" in OS.get_cmdline_user_args():
		#print("hosting on " + str(hostPort))
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
			
			if data.message == Util.Message.update:
				update(data)
				
			if data.message == Util.Message.loginUser:
				login(data)
				
			if data.message == Util.Message.checkIn:
				get_player_data(data)
				
			if data.message == Util.Message.createUser:
				createUser(data)
				
			if data.message ==  Util.Message.offer || data.message == Util.Message.answer || data.message ==  Util.Message.candidate:
				print("source id is " + str(data.orgPeer))
				sendToPlayer(data.peer, data)
				

func peer_connected(id):
	print("Backend Peer Connected: " + str(id))
	users[id] = {
		"id" : id,
		"message" :  Util.Message.id
	}
	peer.get_peer(id).put_packet(JSON.stringify(users[id]).to_utf8_buffer())
	pass
	
func peer_disconnected(id):
	users.erase(id)
	pass
	
func update(data):
	dao.change_data(data.data.name, data.data.change_name, data.data.change)
	
func createUser(data):
	var salt = cryptoUtil.GenerateSalt()
	var hashedPassword = cryptoUtil.HashPassword(data.data.password, salt)
	dao.InsertUserData(data.data.username, hashedPassword, salt)
	login(data)
	
func get_player_data(data):
	var userData = dao.GetUserFromDB(data.data.username)
	var returnData = {
		"username" : userData.name,
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

		
	
func login(data):
	var userData = dao.GetUserFromDB(data.data.username)
	if userData == null:
		var returnData ={
			"message" :Util.Message.failedToLogin,
			"text" : "Failed to login invalid username or password"
		}
		peer.get_peer(data.peer).put_packet(JSON.stringify(returnData).to_utf8_buffer())
		return
	if(userData.hashedPassword == cryptoUtil.HashPassword(data.data.password, userData.salt)):
		var returnData = {
			"username" : userData.name,
			"id" : userData.id,
			"message" : Util.Message.playerinfo,
			"health" : userData.health,
			"Position_x": userData.Position_x,
			"Position_y": userData.Position_y,
			"Position_z": userData.Position_z,
			"Inventory": userData.Inventory,
			"Hotbar": userData.Hotbar,
			 ## add stuff like player pos etc
		}
		peer.get_peer(data.peer).put_packet(JSON.stringify(returnData).to_utf8_buffer())
	else:
		var returnData ={
			"message" :Util.Message.failedToLogin,
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
	peer.create_server(hostPort)
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
