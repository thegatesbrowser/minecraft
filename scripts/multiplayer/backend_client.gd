extends Node

@export var login_window = preload("res://scenes/ui/login_window.tscn")
@export var PlayerInfo:RichTextLabel
@export var LoginWindow:PanelContainer

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
var id = 0
var rtcPeer : WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
var hostId :int
var lobbyValue = ""
var lobbyInfo = {}
var cryptoUtil = UserCrypto.new()
var username:String
# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
	
	if Connection.is_server() == false:
		connectToServer("")
		
	make_login()
	pass # Replace with function body.


func createUser(username, password):
	var data = {"username" : username.strip_edges(true, true), 
	"password" : cryptoUtil.HashData(password.strip_edges(true, true))
	}
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.createUser,
		"data": data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	
func loginUser(username, password):
	var data = {"username" : username.strip_edges(true, true), 
	"password" : cryptoUtil.HashData(password.strip_edges(true, true))
	}
	
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" :  Message.loginUser,
		"data": data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())

func RTCServerConnected():
	print("backend server connected")

func RTCPeerConnected(id):
	print("backend peer connected " + str(id))
	
func RTCPeerDisconnected(id):
	print("backend peer disconnected " + str(id))



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	peer.poll()
	if Input.is_action_just_pressed("0"):
		update({"name": username,"health": 10})
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			
			print(data)
			
			
			if data.message == Message.id:
				id = data.id
				
				connected(id)
				
			#if data.message == Message.userConnected:
				##GameManager.Players[data.id] = data.player
				#createPeer(data.id)
				
			if data.message == Message.candidate:
				if rtcPeer.has_peer(data.orgPeer):
					print("Got Candididate: " + str(data.orgPeer) + " my id is " + str(id))
					rtcPeer.get_peer(data.orgPeer).connection.add_ice_candidate(data.mid, data.index, data.sdp)
			
			if data.message == Message.offer:
				if rtcPeer.has_peer(data.orgPeer):
					rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("offer", data.data)
			
			if data.message == Message.answer:
				if rtcPeer.has_peer(data.orgPeer):
					rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("answer", data.data)
#			if data.message == Message.serverLobbyInfo:
#
#				$LobbyBrowser.InstanceLobbyInfo(data.name,data.userCount)
			if data.message == Message.playerinfo:
				for i in data:
					PlayerInfo.text += str(i,"\n")
				#PlayerInfo.text = data.username + "\n"+ str(data.id)  + "\n" + str(data.health)
				username = data.username
			if data.message == Message.failedToLogin:
				LoginWindow.SetSystemErrorLabel(data.text)
	pass

func update(data:Dictionary):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.update,
		"data": data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	
func connected(id):
	rtcPeer.create_mesh(id)
	multiplayer.multiplayer_peer = rtcPeer

#web rtc connection
func createPeer(id):
	if id != self.id:
		var peer : WebRTCPeerConnection = WebRTCPeerConnection.new()
		peer.initialize({
			"iceServers" : [{ "urls": ["stun:stun.l.google.com:19302"] }]
		})
		print("binding id " + str(id) + "my id is " + str(self.id))
		
		peer.session_description_created.connect(self.offerCreated.bind(id))
		peer.ice_candidate_created.connect(self.iceCandidateCreated.bind(id))
		rtcPeer.add_peer(peer, id)
		
		if !hostId == self.id:
			peer.create_offer()
		pass
		

func offerCreated(type, data, id):
	if !rtcPeer.has_peer(id):
		return
		
	rtcPeer.get_peer(id).connection.set_local_description(type, data)
	
	if type == "offer":
		sendOffer(id, data)
	else:
		sendAnswer(id, data)
	pass
	
	
func sendOffer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" :  Message.offer,
		"data": data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass

func sendAnswer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.answer,
		"data": data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass

func iceCandidateCreated(midName, indexName, sdpName, id):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" :  Message.candidate,
		"mid": midName,
		"index": indexName,
		"sdp": sdpName,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass

func connectToServer(ip):
	peer.create_client("ws://127.0.0.1:8915")
	print("started client")


func _on_start_client_button_down():
	connectToServer("")
	pass # Replace with function body.

func make_login():
	var login = login_window.instantiate()
	login.CreateUser.connect(createUser)
	login.LoginUser.connect(loginUser)
	add_child(login)
	LoginWindow = login
