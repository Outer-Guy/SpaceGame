extends Node

func load_scene(path : String) -> void :
	get_tree().change_scene_to_file(path)
