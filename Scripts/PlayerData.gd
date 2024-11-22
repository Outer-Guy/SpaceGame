extends Node

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

func _ready() -> void:
	multiplayer.peer_disconnected.connect(on_peer_disconnected)

func log_all() -> void:
	print(local.username + " got:")
	for data : PlayerInfo in all_data.values():
		data.log()

# Stores all PlayerInfo from players, should not be accessed directly outside this script
var all_data : Dictionary = {}
signal on_all_data_set

# -------------- GETTERS --------------------
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

# -------------- SETTERS --------------------
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

# -------------- SYNCING --------------------

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

# ---------------- EXTRA ------------------ 

func create_empty_server() -> void :
	var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error : Error = peer.create_server(4444, 1)
	if error : get_tree().quit()
	multiplayer.set_multiplayer_peer(peer)
	create_player_data(1, "debugPlayer")
	set_gamestate(1, PlayerData.GAMESTATE.PLAYING)
