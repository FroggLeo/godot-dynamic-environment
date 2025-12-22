@tool
extends Node3D

@export var paused: bool = false
## length of one day in seconds
@export var day_length: float = 120

## tilt variance of the sun and moon based on season
# TODO add seasonal tilt
@export var axial_tilt: float = 23.5:
	set (value):
		axial_tilt = value
## latitude / base tilt
@export_range(-90,90,0.01) var latitude: float = 34.05:
	set (value):
		latitude = value

@export_range(0,1,0.001) var time: float = 0:
	set (value):
		time = value
		_update_sun_moon()

@onready var Sun := $Sun # node3d of sun
@onready var SunLight := $Sun/SunLight # directional light of sun
@onready var Moon := $Moon # node3d of moon
@onready var MoonLight := $Moon/MoonLight # directional light of moon

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if paused:
		return
	_update_time(delta)
	_update_sun_moon()
	

func _update_time(delta: float) -> void:
	time += delta / day_length
	if time >= 1.0:
		time -= 1.0

func _update_sun_moon() -> void:
	var angle := time * TAU
	
	var elevation_angle := angle - PI * 0.5
	
	Sun.rotation = Vector3(
		elevation_angle + deg_to_rad(latitude),
		deg_to_rad(latitude),
		0.0
	)
	# add pi to set to exactly opposite
	Moon.rotation = Sun.rotation + Vector3(PI, 0.0, 0.0)
