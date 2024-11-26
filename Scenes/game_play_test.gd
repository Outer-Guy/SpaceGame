extends Node2D

@export var player_prefab : PackedScene
@export var follow_camera : bool = true

func _ready() -> void:
	if PlayerData.all_data.is_empty() : PlayerData.create_empty_server()
	if !follow_camera : $"Camera2D".anchor_mode = Camera2D.AnchorMode.ANCHOR_MODE_FIXED_TOP_LEFT
	
	var index : int = 0
	var spawnPoints : Array = get_tree().get_nodes_in_group("SpawnPoint")
	for data : PlayerData.PlayerInfo in PlayerData.all_data.values() :
		var new_player : Node = player_prefab.instantiate()
		new_player.assigned_id = data.id
		add_child(new_player)
		if follow_camera && data.id == PlayerData.local.id : $"Camera2D".reparent(new_player)
		new_player.global_position = spawnPoints[index].global_position
		index += 1

func onCollectedParticle() -> void:
	pass
