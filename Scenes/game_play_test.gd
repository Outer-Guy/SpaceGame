extends Node2D

@export var timer : float
var rounded_timer : int
signal OnTimerChange(newTime : int)

@export var player_prefab : PackedScene
@export var objective_prefab : PackedScene
@export var follow_camera : bool = true

var points : int
@export var startingPoints : int
@export var minPointSpawn : Vector2
@export var maxPointSpawn : Vector2
func random_spawn_position() -> Vector2 : return Vector2(randf_range(minPointSpawn.x,maxPointSpawn.x),randf_range(minPointSpawn.y,maxPointSpawn.y))
signal OnPointsChange(points : int)

func _ready() -> void:
	rounded_timer = int(timer)
	OnTimerChange.emit(rounded_timer)
	if PlayerData.all_data.is_empty() : PlayerData.create_empty_server()
	if !follow_camera : $"Camera2D".anchor_mode = Camera2D.AnchorMode.ANCHOR_MODE_FIXED_TOP_LEFT
	
	var index : int = 0
	var spawnPoints : Array = get_tree().get_nodes_in_group("SpawnPoint")
	for data : PlayerData.PlayerInfo in PlayerData.all_data.values() :
		var new_player : Node = player_prefab.instantiate()
		new_player.assigned_id = data.id
		add_child(new_player)
		new_player.name = "Player"
		if follow_camera && data.id == PlayerData.local.id : $"Camera2D".reparent(new_player)
		new_player.global_position = spawnPoints[index].global_position
		index += 1
	if multiplayer.is_server():
		while startingPoints > 0:
			onSpawnObjective.rpc(random_spawn_position())
			startingPoints -= 1

func _process(delta: float) -> void:
	timer -= delta
	if timer <= rounded_timer - 1 : 
		rounded_timer -= 1
		OnTimerChange.emit(rounded_timer)
	if multiplayer.is_server() && timer <= 0:
		GameManager.points.append(points)
		GameManager.points.sort_custom(sort_descending)
		GameManager.load_scene.rpc("res://Scenes/MultiplayerLobby.tscn")
	

@rpc("authority","call_local")
func onSpawnObjective(spawn_position : Vector2) -> void:
	var new_objective : Node = objective_prefab.instantiate()
	add_child(new_objective)
	new_objective.position = spawn_position
	new_objective.Collected.connect(onCollectedParticle)

func onCollectedParticle() -> void:
	if multiplayer.is_server() : onSpawnObjective.rpc.call_deferred(random_spawn_position())
	points += 1
	OnPointsChange.emit(points)

func sort_descending(a : int, b : int) -> bool : return a > b
