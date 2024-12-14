extends Control

@export var active : bool = true

@export_group("Window Settings", "window")
@export var window_size : Vector2 = Vector2(300, 400)
@export var window_position : Vector2 = Vector2(0,0)
@export var window_borderless : bool = true
@export var window_resizable : bool = false

var variables : Dictionary = {}
var text : String = ""

var window : Window
@onready var window_content : Node = $WindowContent
@onready var text_label : RichTextLabel = $WindowContent/WindowText

func _ready() -> void:
	if !active : queue_free()
	
	get_viewport().set_embedding_subwindows(false)
	window = Window.new()
	config_window()
	add_child(window)
	window_content.reparent(window)

func config_window() -> void :
	window.size = window_size
	window.position = window_position
	window.borderless = window_borderless
	window.unresizable = !window_resizable

func set_value(key: String, value: Variant) -> void:
	if(variables.has(key) && variables[key] == value): return
	variables[key] = value
	update_view()

func remove_value(key : String) -> void:
	variables.erase(key)
	update_view()

func update_view() -> void:
	text = "\n"
	for variable_key : String in variables.keys():
		text += "	" + variable_key + ": " + str(format_value(variables[variable_key])) + "\n"
	
	text_label.text = text 

func format_value(value : Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT : return snapped(value, 0.01)
		TYPE_VECTOR2 : return snapped(value, Vector2(0.01, 0.01))
		TYPE_VECTOR3 : return snapped(value, Vector3(0.01, 0.01, 0.01))
	return ""
