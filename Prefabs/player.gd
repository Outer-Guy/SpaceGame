extends CharacterBody2D

@export var MAXSPEED: float = 300
@export var ACCELERATION: float = 0.01
@export var SPEEDPOWER: float = 2
@export var RotationWeight: float = 0.75

var TRYHOOK : bool = false
var CLICKPOSITION: Vector2
var tempD: Dictionary
var RelativeHookAngle : Vector2
var AcSpeed : float

func _ready() -> void:
	pass # Replace with function body.
	
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	BasicForce()
	if TRYHOOK:
		HookLogic()
	
	
	transform = transform.orthonormalized()
	move_and_slide()
	
#Handles touch input
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		
		TRYHOOK = event.pressed
		CLICKPOSITION = event.position

#Handles Hook Physics
func HookLogic() -> void:
#region RaycastToTouch
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, CLICKPOSITION)
	var result: Dictionary = space_state.intersect_ray(query)
	tempD = result
#endregion
	
	if !result.is_empty():
		queue_redraw()
		RelativeHookAngle = tempD.get("collider").position - position
		RelativeHookAngle = RelativeHookAngle
		#Vector2 TargetSpeed = 
	else:
		TRYHOOK = false
		RelativeHookAngle = velocity.normalized() 
	

func BasicForce() -> void:
	var SPEEDFORCE : float = ((MAXSPEED - velocity.length()) * ACCELERATION) ** SPEEDPOWER #+ velocity.length()
	#velocity = Vector2(SPEEDFORCE*cos(RelativeHookAngle),SPEEDFORCE* sin(RelativeHookAngle))
	velocity = (velocity.length() + SPEEDFORCE) * lerp(velocity.normalized(),Vector2(-RelativeHookAngle.y,RelativeHookAngle.x).normalized(),RotationWeight)
	look_at(position+velocity)
	print(velocity)

func _draw() -> void:
	if !tempD.is_empty():
		draw_line(Vector2.ZERO, transform.x,Color.WHITE,-1)
		#print(global_position,tempD.get("collider").position)
