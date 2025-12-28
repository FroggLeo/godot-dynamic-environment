extends Camera3D

@export var sensitivity := 0.2

var last_mouse_pos: Vector2

func _ready() -> void:
	print("camera readying..")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("move_camera"):
		last_mouse_pos = get_viewport().get_mouse_position()
	elif event is InputEventMouseMotion and Input.is_action_pressed("move_camera"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		rotation_degrees.y -= event.relative.x * sensitivity
		rotation_degrees.x -= event.relative.y * sensitivity
		rotation_degrees.x = clamp(rotation_degrees.x, -90, 90)
	elif Input.is_action_just_released("move_camera"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Input.warp_mouse(last_mouse_pos)

func _process(_delta: float) -> void:
	pass
