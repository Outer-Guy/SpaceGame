extends Node

enum GAMESTATE {
	MAIN_MENU,
	LOBBY,
	PLAYING
}

var gamestate : GAMESTATE = GAMESTATE.MAIN_MENU

var Players : Dictionary = {}
