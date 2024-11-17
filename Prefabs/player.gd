extends CharacterBody2D


@export var SPEED: float = 300.0
@export var JUMP_VELOCITY: float = -400.0
var TRYHOOK : bool = false
var CLICKPOSITION: Vector2
var tempD: Dictionary


func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	
	velocity = transform.x * SPEED
	
	if TRYHOOK:
		Input()
	
	move_and_slide()
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		
		TRYHOOK = event.pressed
		CLICKPOSITION = event.position

func Input() -> void:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, CLICKPOSITION)
	var result: Dictionary = space_state.intersect_ray(query)
	tempD = result
	if !result.is_empty():
		queue_redraw()
	else:
		TRYHOOK = false
		
		
func _draw() -> void:
	if !tempD.is_empty():
		draw_line(Vector2.ZERO, tempD.get("position") - global_position,Color.WHITE,-1)
		print(global_position,tempD.get("position"))
