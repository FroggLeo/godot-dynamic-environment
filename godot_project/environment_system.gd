@tool
extends Node3D

# +x / -x
# east / west 
# +z / -z
# north / south

@export var paused: bool = false

@export var environment: WorldEnvironment
@export_range(0.0, 1.0, 0.001) var humidity := 0.35: set = _set_humidity
@export_range(0.0, 500.0, 1.0) var aqi := 35.0: set = _set_aqi
@export_range(1.0, 50.0, 0.1) var visibility_km := 30.0: set = _set_visibility

@export_range(-30.0, 45.0, 0.1) var temperature_c := 30.0: set = _set_temperature
@export_range(150.0, 450.0, 1.0) var ozone_du := 300.0: set = _set_ozone

@export_range(0.5, 99999.0, 0.01) var camera_altitude := 0.5: set = _set_altitude

@onready var Sun := $SunLight # directional light of sun
@onready var Moon := $MoonLight # directional light of moon

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if paused:
		return
	

func _get_light_dir(light: DirectionalLight3D) -> Vector3:
	return (-light.global_transform.basis.z).normalized()

func _set_humidity(value): humidity = value
func _set_aqi(value): aqi = value
func _set_visibility(value): visibility_km = value
func _set_temperature(value): temperature_c = value
func _set_ozone(value): ozone_du = value
func _set_altitude(value): camera_altitude = value
