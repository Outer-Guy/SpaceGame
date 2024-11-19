extends Node

signal onRecievedPlayerData

enum GAMESTATE {
	MAIN_MENU,
	LOBBY,
	PLAYING
}

var gamestate : GAMESTATE = GAMESTATE.MAIN_MENU

var Players : Dictionary = {}
var localUsername : String = ""

func load_scene(path : String) -> void :
	get_tree().change_scene_to_file(path)

@rpc("any_peer", "call_local")
func set_gamestate(caller_id : int, state : GAMESTATE) -> void :
	if(Players.has(caller_id)) :
		Players[caller_id]["gamestate"] = state
	if multiplayer.get_unique_id() == caller_id :
		gamestate = state

@rpc("any_peer", "call_remote")
func send_player_info(id: int, username: String) -> void:
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"id" = id,
			"username" = username,
			"gamestate" = GameManager.GAMESTATE.MAIN_MENU,
			"Ready" = false
		}
		
	onRecievedPlayerData.emit()
	print("---" + GameManager.localUsername + "---")
	print(GameManager.Players)
	print("---------------------")
	if multiplayer.is_server():
		for i : int in GameManager.Players:
			send_player_info.rpc(i, GameManager.Players[i].username)
