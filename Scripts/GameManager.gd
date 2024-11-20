extends Node

func _ready() -> void:
	PlayerData.on_all_data_set.connect(PlayerData.log_all)

@rpc("authority", "call_local")
func load_scene(path : String) -> void :
	get_tree().change_scene_to_file(path)
