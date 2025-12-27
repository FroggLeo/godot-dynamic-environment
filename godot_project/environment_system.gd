@tool
extends Node3D

# +x / -x
# east / west 
# +z / -z
# north / south

@export var paused: bool = false

@export var environment: WorldEnvironment
@export var sky_material: ShaderMaterial
@export_range(0.0, 1.0, 0.001) var humidity := 0.35: set = _set_humidity
@export_range(0.0, 500.0, 1.0) var aqi := 35.0: set = _set_aqi
@export_range(0.1, 50.0, 0.1) var visibility_km := 30.0: set = _set_visibility

@export_range(-35.0, 45.0, 0.1) var temperature_c := 30.0: set = _set_temperature
@export_range(150.0, 450.0, 1.0) var ozone_du := 300.0: set = _set_ozone

@export_range(0.5, 99999.0, 0.01) var camera_altitude := 0.5: set = _set_altitude

@onready var Sun := $SunLight # directional light of sun
@onready var Moon := $MoonLight # directional light of moon
# the sky shader material
var mat: ShaderMaterial

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_resolve_sky_material()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if paused:
		return

func _resolve_sky_material() -> void:
	if sky_material:
		mat = sky_material
	if not environment: # if environment is not set
		return
	var sky = environment.environment.sky
	if sky and sky.sky_material is ShaderMaterial:
		mat = sky.sky_material

func _update_atmosphere() -> void:
	if not mat:
		print("noooooooo")
		return
	# normalize to 0..1 as needed
	var hu := humidity
	# 0..500 to 0..1
	var aq: float = clamp(aqi / 500, 0, 1)
	# 0..50 to 1..0
	var vi: float = clamp((50 - visibility_km) / 50, 0, 1)
	# get a nice haze out of all 3 values
	# idea is adapted from aerosol optical depth
	# visibility has the most effect, then aqi, then humidity has the smallest
	var haze: float = pow(clamp(0.55 * vi + 0.30 * aq + 0.25 * hu, 0, 1), 1.4)
	var mie_strength: float = lerp(0.2, 5.0, haze);
	# just put in the clean air mie g and polluted mie g
	var mie_g: float = lerp(0.76, 0.93, clamp(haze * 0.9 + hu * 0.2, 0, 1))
	# rayleigh strength drops as haze increases
	var rayleigh_strength: float = lerp(1.3, 0.7, clamp(aq * 0.9 + haze * 0.4, 0, 1))
	# ozone
	# 150..450 to 0..1
	var oz: float = clamp((ozone_du - 150) / 300, 0, 1)
	var ozone_strength: float = lerp(0.8, 1.2, oz)
	# temperature effect on haze
	# -35..45 to 0..1
	var te: float = clamp((temperature_c + 35) / 80, 0, 1)
	mie_strength *= lerp(0.9, 1.1, te)
	# update shader now
	mat.set_shader_parameter("camera_altitude", camera_altitude)
	mat.set_shader_parameter("rayleigh_strength", rayleigh_strength)
	mat.set_shader_parameter("mie_strength", mie_strength)
	mat.set_shader_parameter("mie_g", mie_g)
	mat.set_shader_parameter("ozone_strengh", ozone_strength)

func _get_light_dir(light: DirectionalLight3D) -> Vector3:
	return (-light.global_transform.basis.z).normalized()

func _set_humidity(value): humidity = value; _update_atmosphere()
func _set_aqi(value): aqi = value; _update_atmosphere()
func _set_visibility(value): visibility_km = value; _update_atmosphere()
func _set_temperature(value): temperature_c = value; _update_atmosphere()
func _set_ozone(value): ozone_du = value; _update_atmosphere()
func _set_altitude(value): camera_altitude = value; _update_atmosphere()
