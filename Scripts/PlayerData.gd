extends Node

#region DEFINITIONS
enum GAMESTATE {
	MAIN_MENU,
	LOBBY,
	PLAYING
}

class PlayerInfo:
	var id : int
	var username : String
	var gamestate : GAMESTATE = GAMESTATE.MAIN_MENU
	var ready : bool
	
	static func create(new_id : int, new_username : String) -> PlayerInfo :
		var player_info: PlayerInfo = PlayerInfo.new()
		player_info.id = new_id
		player_info.username = new_username
		player_info.gamestate = GAMESTATE.MAIN_MENU
		player_info.ready = false
		return player_info
	
	static func serialize(data : PlayerInfo) -> Array :
		return [data.id, data.username, data.gamestate, data.ready]
	
	static func deserialize(serializedData : Array) -> PlayerInfo :
		var data : PlayerInfo = PlayerInfo.create(serializedData[0], serializedData[1])
		data.gamestate = serializedData[2]
		data.ready = serializedData[3]
		return data
	
	func log() -> void :
		var msg : String = ""
		msg += "("
		if self.id == 1 : msg += "Host"
		else : msg += "Client"
		msg += ", ID: " + str(self.id) + ") " + self.username + ": "
		msg += "is "
		match self.gamestate:
			GAMESTATE.MAIN_MENU:
				msg += "on Main Menu"
			GAMESTATE.LOBBY:
				msg += "on Lobby, "
				if !self.ready: msg += "not "
				msg += "ready"
			GAMESTATE.PLAYING:
				msg += "playing"
		# EXAMPLE : 
		# (Host, ID: 1) Gero: is on Lobby, not ready
		print(msg)
#endregion

func _ready() -> void:
	multiplayer.peer_disconnected.connect(on_peer_disconnected)

func _process(delta : float) -> void:
	if broadcast_timer_active : 
		broadcast_timer += delta
		if broadcast_timer >= broadcast_interval_in_seconds : 
			_on_broadcast_timer_timeout()
			broadcast_timer = 0
	if listen_timer_active : 
		listen_timer += delta
		if listen_timer >= broadcast_interval_in_seconds/3 : 
			_on_listen_timer_timeout()
			listen_timer = 0

func log_all() -> void:
	print(local.username + " got:")
	for data : PlayerInfo in all_data.values():
		data.log()

# Stores all PlayerInfo from players, should not be accessed directly outside this script
var all_data : Dictionary = {}
signal on_all_data_set

#region GETTERS
# Returns PlayerInfo referring to local player
var local : PlayerInfo:
	get:
		return all_data[multiplayer.get_unique_id()]

# Returns PlayerInfo from id
func by_id(id : int) -> PlayerInfo : return all_data[id]

# Return PlayerInfo searching all players with the username
func by_username(user : String) -> Array :
	var list : Array = []
	for info : PlayerInfo in all_data.values() : 
		if info.username == user : list.append(info)
	return list

func all_ready() -> bool :
	var are_ready : bool = true
	for data : PlayerInfo in all_data.values() :
		are_ready = are_ready && data.ready
	return are_ready

#endregion

#region SETTERS
func check_id(id : int) -> bool :
	if(all_data.has(id)) :
		return true
	else : 
		printerr(local.username + " tried to set info of inexistent player, id: "
		+ str(id) + ". Asking for sync.")
		
		ask_for_missing.rpc_id(1)
		return false

@rpc("any_peer", "call_local")
func set_username(id : int, username : String) -> void :
	if check_id(id) : all_data[id].username = username


@rpc("any_peer", "call_local")
func set_ready(id : int, state : bool) -> void :
	if check_id(id) : all_data[id].ready = state
	if multiplayer.is_server() && all_ready() :
		pass # TODO

@rpc("any_peer", "call_local")
func set_gamestate(id: int , state : GAMESTATE) -> void :
	if check_id(id) : all_data[id].gamestate = state
#endregion

#region SYNCING
func on_peer_disconnected(id : int) -> void :
	if multiplayer.is_server() :
		remove_player_data.rpc(id)

@rpc("any_peer", "call_remote")
func ask_for_missing() -> void :
	if multiplayer.is_server() :
		for data : PlayerInfo in all_data.values():
			create_player_data.rpc_id(multiplayer.get_remote_sender_id(), data.id, data.username)
	else : printerr("Some client is trying to send missing info.")

@rpc("any_peer", "call_remote")
func sync_all() -> void :
	if multiplayer.is_server() :
		var serialized_all_data : Array = []
		for data : PlayerInfo in all_data.values():
			serialized_all_data.append(PlayerInfo.serialize(data))
		set_all_data.rpc(serialized_all_data)

# Create PlayerInfo if non existent
@rpc("authority", "call_local")
func create_player_data(id : int, username : String) -> void :
	if !all_data.has(id):
		all_data[id] = PlayerInfo.create(id, username)

# Remove PlayerInfo if existent
@rpc("authority", "call_local")
func remove_player_data(id : int) -> void :
	if all_data.has(id):
		all_data.erase(id)

@rpc("any_peer", "call_remote")
func on_player_connected(id: int, username: String) -> void:
	if multiplayer.is_server() :
		create_player_data(id, username)
		sync_all()
		

# Override all_data sent
@rpc("authority", "call_remote")
func set_all_data(serialized_all_data : Array) -> void :
	for serialized_data : Array in serialized_all_data :
		set_player_data(serialized_data)
	on_all_data_set.emit()

# Override PlayerData sent
@rpc("authority", "call_remote")
func set_player_data(serialized_data : Array) -> void :
	# serialized_data[0] has a reference to the id sent
	if all_data.has(serialized_data[0]) : all_data.erase(serialized_data[0])
	all_data[serialized_data[0]] = PlayerInfo.deserialize(serialized_data)
#endregion

#region BROADCASTING

var broadcast_interval_in_seconds : float = 6
var broadcast_address : String = '255.255.255.255'

var lobby_info : Dictionary
var all_lobby_data : Array = []
signal on_all_lobby_data_changed

var listen_timer_active : bool = false
var listen_timer : float = 0
var listener : PacketPeerUDP
var listen_port : int = GameManager.port

var broadcast_timer_active : bool = false
var broadcast_timer : float = 0
var broadcaster : PacketPeerUDP
var broadcast_port : int = GameManager.port + 1


func setup_listener() -> void :
	listener = PacketPeerUDP.new()
	var error : Error = listener.bind(listen_port)
	if error :
		print("Error setting up listen port " + str(listen_port))
		print(error)
		return
	
	print("listen set up to port " + str(listen_port))
	listen_timer_active = true

func setup_broadcast(lobbyName : String) -> void:
	lobby_info.name = lobbyName
	lobby_info.ip = GameManager.address
	lobby_info.playerCount = all_data.size()
	
	print(lobby_info)
	
	broadcaster = PacketPeerUDP.new()
	broadcaster.set_broadcast_enabled(true)
	broadcaster.set_dest_address(broadcast_address, listen_port)
	
	var error : Error = broadcaster.bind(broadcast_port)
	if error :
		print("Error setting up broadcast")
		print(error)
		return
	
	print("broadcast set up to port " + str(broadcast_port))
	
	broadcast_timer_active = true

func _on_broadcast_timer_timeout() -> void:
	lobby_info.playerCount = PlayerData.all_data.size()
	var error : Error = broadcaster.put_packet(JSON.stringify(lobby_info).to_utf8_buffer())
	if error :
		printerr("Error while sending broadcast packet")
		printerr(error)

func _on_listen_timer_timeout() -> void :
	if listener == null : return
	if listener.get_available_packet_count() > 0 :
		var data_recieved : Dictionary = JSON.parse_string(listener.get_packet().get_string_from_utf8())
		# print("Packet recieved from " + str(listener.get_packet_ip()) + ":" + str(listener.get_packet_port()))
		data_recieved.ip = listener.get_packet_ip()
		handle_lobby_data(data_recieved)

func handle_lobby_data(new_data : Dictionary) -> void :
	if all_lobby_data.is_empty() : 
		all_lobby_data.append(new_data)
		on_all_lobby_data_changed.emit()
	
	for data : Dictionary in all_lobby_data:
		if data.ip == new_data.ip && data != new_data :
			all_lobby_data.erase(data)
			all_lobby_data.append(new_data)
			on_all_lobby_data_changed.emit()

func clean_up_broadcasting() -> void :
	if listener != null : listener.close()
	if broadcaster != null : broadcaster.close()
	listen_timer_active = false
	broadcast_timer_active = false

#endregion

#region EXTRA
func create_empty_server() -> void :
	var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error : Error = peer.create_server(4444, 1)
	if error : get_tree().quit()
	multiplayer.set_multiplayer_peer(peer)
	create_player_data(1, "debugPlayer")
	set_gamestate(1, PlayerData.GAMESTATE.PLAYING)
#endregion
