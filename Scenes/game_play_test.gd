extends Node2D

signal OnPointsChange(points : int)
signal OnTimerChange(newTime : int)

@export var player_prefab : PackedScene
@export var objective_prefab : PackedScene
@export var follow_camera : bool = true

@export var points : int
@export var startingPoints : int = 1
@export var timer : float = 3 

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
	if multiplayer.is_server():
		while startingPoints > 0:
			onSpawnObjective.rpc(Vector2(randf_range(100,1100),randf_range(100,500)))
			startingPoints -= 1
			print("SpawnedPoint")
		
func _process(delta: float) -> void:
	timer -= delta
	OnTimerChange.emit(ceil(timer))
	if multiplayer.is_server() && timer <= 0:
		GameManager.points.append(points)
		GameManager.points.sort_custom(sort_descending)
		GameManager.load_scene.rpc("res://Scenes/MultiplayerLobby.tscn")
	

@rpc("authority","call_local")
func onSpawnObjective(position : Vector2) -> void:
	var new_objective : Node = objective_prefab.instantiate()
	add_child(new_objective)
	new_objective.position = position
	new_objective.Collected.connect(onCollectedParticle)

func onCollectedParticle(collectedNode : Node2D) -> void:
	onSpawnObjective.rpc(Vector2(randf_range(100,300),randf_range(100,300)))
	points +=1
	OnPointsChange.emit(points)
	pass

func sort_descending(a : int, b : int) -> bool:
	if a > b:
		return true
	return false
