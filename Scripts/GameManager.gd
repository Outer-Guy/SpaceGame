extends Node

enum GAMESTATE {
	MAIN_MENU,
	LOBBY,
	PLAYING
}

var gamestate : GAMESTATE = GAMESTATE.MAIN_MENU

var Players : Dictionary = {}
var localUsername : String = ""

func load_scene(path : String) -> void :
	get_tree().root.add_child(load(path).instantiate())

@rpc("any_peer", "call_local")
func set_gamestate(caller_id : int, state : GAMESTATE) -> void :
	if(Players.has(caller_id)) :
		Players[caller_id]["gamestate"] = state
	if multiplayer.get_unique_id() == caller_id :
		gamestate = state
