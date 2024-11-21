extends Node2D

@export var player_prefab : PackedScene

func _ready() -> void:
	var index : int = 0
	var spawnPoints : Array = get_tree().get_nodes_in_group("SpawnPoint")
	for data : PlayerData.PlayerInfo in PlayerData.all_data.values() :
		var new_player : Node = player_prefab.instantiate()
		new_player.assigned_id = data.id
		add_child(new_player)
		new_player.global_position = spawnPoints[index].global_position
		index += 1
