extends Node

@export var debug_ui:Control
@export var PlayerInfo:RichTextLabel
#@export var address:String = "ws://127.0.0.1:8819"

@export var address:String = "ws://188.245.188.59:8819"
signal playerdata_updated

var peer = WebSocketMultiplayerPeer.new()
var id = 0
var rtcPeer: WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
var hostId: int
var lobbyValue = ""
var lobbyInfo = {}
var cryptoUtil = UserCrypto.new()
var client_id: String

const CLIENT_ID_PATH := "user://client_id.txt"

var playerdata:Dictionary = {}


func _ready():
	Console.add_command("saveD", self, 'saveD')\
		.set_description("shows the saved player data from the backend).")\
		.register()
	#Globals.send_data.connect(update)
	Globals.send_slot_data.connect(update_slot)
	Globals.send_to_server.connect(_update)
	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
	
	if Connection.is_server() == false:
		connectToServer("")


func ask_for_player_data(cid):
	var data = {"client_id" : cid.strip_edges(true, true)}
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" :  Util.Message.checkIn,
		"data": data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())


func identify():
	var cid := get_saved_client_id()
	var data := {"client_id": cid}
	var message := {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Util.Message.identify,
		"data": data,
		"Lobby": lobbyValue
	}
	print("sent identify message", message)
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())


func RTCServerConnected():
	print("backend server connected")

func RTCPeerConnected(peer_id):
	print("backend peer connected " + str(peer_id))

func RTCPeerDisconnected(peer_id):
	print("backend peer disconnected " + str(peer_id))



func _process(_delta):
	if Input.is_action_just_pressed("0"):
		ask_for_player_data(client_id)
	
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			
			#print(data)
			
			if data.message == Util.Message.id:
				id = data.id
				connected(id)
				identify()
			
			#if data.message == Util.Message.userConnected:
				##GameManager.Players[data.id] = data.player
				#createPeer(data.id)
			
			if data.message == Util.Message.candidate:
				if rtcPeer.has_peer(data.orgPeer):
					print("Got Candididate: " + str(data.orgPeer) + " my id is " + str(id))
					rtcPeer.get_peer(data.orgPeer).connection.add_ice_candidate(data.mid, data.index, data.sdp)
			
			if data.message == Util.Message.offer:
				if rtcPeer.has_peer(data.orgPeer):
					rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("offer", data.data)
			
			if data.message == Util.Message.answer:
				if rtcPeer.has_peer(data.orgPeer):
					rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("answer", data.data)
			
			if data.message == Util.Message.playerinfo:
				playerdata = data
				playerdata_updated.emit()
				#print(playerdata)
				PlayerInfo.text = ""
				for i in data:
					var variable = data[i]
					PlayerInfo.text += str(i," : ",variable,"\n")
				
				#PlayerInfo.text = data.client_id + "\n"+ str(data.id)  + "\n" + str(data.health)
				client_id = data.client_id
				Globals.client_id = client_id
				save_client_id(client_id)


func update_slot(slot_data:Dictionary): ##{index: int, item_path: String, amount: int,parent: String,health: int, rot:int, client_id:String}
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Util.Message.slot_update,
		"data": slot_data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())


func _update(data:Dictionary):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Util.Message.update,
		"data": data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	

func connected(peer_id):
	rtcPeer.create_mesh(peer_id)
	multiplayer.multiplayer_peer = rtcPeer


#web rtc connection
func createPeer(peer_id):
	if peer_id != self.id:
		var wrtc_peer : WebRTCPeerConnection = WebRTCPeerConnection.new()
		wrtc_peer.initialize({
			"iceServers" : [{ "urls": ["stun:stun.l.google.com:19302"] }]
		})
		print("binding id " + str(peer_id) + "my id is " + str(self.id))
		
		wrtc_peer.session_description_created.connect(self.offerCreated.bind(peer_id))
		wrtc_peer.ice_candidate_created.connect(self.iceCandidateCreated.bind(peer_id))
		rtcPeer.add_peer(wrtc_peer, peer_id)
		
		if !hostId == self.id:
			wrtc_peer.create_offer()


func offerCreated(type, data, peer_id):
	if !rtcPeer.has_peer(id):
		return
		
	rtcPeer.get_peer(peer_id).connection.set_local_description(type, data)
	
	if type == "offer":
		sendOffer(peer_id, data)
	else:
		sendAnswer(peer_id, data)


func sendOffer(peer_id, data):
	var message = {
		"peer" : peer_id,
		"orgPeer" : self.id,
		"message" :  Util.Message.offer,
		"data": data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())


func sendAnswer(peer_id, data):
	var message = {
		"peer" : peer_id,
		"orgPeer" : self.id,
		"message" : Util.Message.answer,
		"data": data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())


func iceCandidateCreated(midName, indexName, sdpName, peer_id):
	var message = {
		"peer" : peer_id,
		"orgPeer" : self.id,
		"message" :  Util.Message.candidate,
		"mid": midName,
		"index": indexName,
		"sdp": sdpName,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())


func connectToServer(_ip):
	peer.create_client(address)
	print("started client trying to connect or ", address)


func _on_start_client_button_down():
	connectToServer("")


func saveD():
	debug_ui.visible = !debug_ui.visible


func get_saved_client_id() -> String:
	if FileAccess.file_exists(CLIENT_ID_PATH):
		var f := FileAccess.open(CLIENT_ID_PATH, FileAccess.READ)
		var s := f.get_as_text().strip_edges(true, true)
		f.close()
		return s
	return ""


func save_client_id(cid: String) -> void:
	var f := FileAccess.open(CLIENT_ID_PATH, FileAccess.WRITE)
	f.store_string(cid)
	f.close()
