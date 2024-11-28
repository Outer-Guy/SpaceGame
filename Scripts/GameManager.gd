extends Node

var port : int = 4444
var address : String = get_local_ip()
var max_players : int = 4
var points : Array[int] = [0]

func _ready() -> void:
	PlayerData.on_all_data_set.connect(PlayerData.log_all)

@rpc("authority", "call_local")
func load_scene(path : String) -> void :
	get_tree().change_scene_to_file(path)

func get_local_ip() -> String:
	var ip : String = ""
	for ipString : String in IP.get_local_addresses():
		if "." in ipString and not ipString.begins_with("127.") and not ipString.begins_with("169.254."):
			if ipString.begins_with("192.168.") or ipString.begins_with("10.") or (ipString.begins_with("172.") and int(ipString.split(".")[1]) >= 16 and int(ipString.split(".")[1]) <= 31):
				ip = ipString
				break
	return ip
