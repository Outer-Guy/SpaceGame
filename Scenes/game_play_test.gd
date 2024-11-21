extends Node2D

@export var player_prefab : PackedScene

func _ready() -> void:
	if multiplayer.get_peers().is_empty() : create_empty_server()
	
	var index : int = 0
	var spawnPoints : Array = get_tree().get_nodes_in_group("SpawnPoint")
	for data : PlayerData.PlayerInfo in PlayerData.all_data.values() :
		var new_player : Node = player_prefab.instantiate()
		new_player.assigned_id = data.id
		add_child(new_player)
		if data.id == PlayerData.local.id : $"Camera2D".reparent(new_player)
		new_player.global_position = spawnPoints[index].global_position
		index += 1

func create_empty_server() -> void :
	var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(4444, 1)
	multiplayer.set_multiplayer_peer(peer)
	PlayerData.create_player_data(1, "debugPlayer")
	PlayerData.set_gamestate(1, PlayerData.GAMESTATE.PLAYING)
