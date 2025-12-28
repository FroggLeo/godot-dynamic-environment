#@tool
extends Node3D

# +x / -x
# east / west 
# +z / -z
# north / south

@export var paused: bool = true

@export var environment: WorldEnvironment
@export var sky_material: ShaderMaterial

@export_range(0.0, 1.0, 0.001) var humidity := 0.35: 
	set(v): humidity = v; _update_atmosphere()
@export_range(0.0, 500.0, 1.0) var aqi := 35.0:
	set(v): aqi = v; _update_atmosphere()
@export_range(0.1, 50.0, 0.1) var visibility_km := 30.0:
	set(v): visibility_km = v; _update_atmosphere()

@export_range(-35.0, 45.0, 0.1) var temperature_c := 30.0:
	set(v): temperature_c = v; _update_atmosphere()
@export_range(150.0, 450.0, 1.0) var ozone_du := 300.0:
	set(v): ozone_du = v; _update_atmosphere()

@export_range(1.0, 99999.0, 0.01) var camera_altitude := 0.5:
	set(v): camera_altitude = v; _update_atmosphere()

@export var day_length: float = 20.0
@export var moon_length: float = 29.5
@export_range(0.0, 1.0, 0.001) var time: float = 0.0:
	set(v): time = v; _update_sun_moon()
@export_range(0.0, 1.0, 0.001) var moon_time: float = 0.0:
	set(v): moon_time = v; _update_sun_moon()

@onready var sunLight := $SunLight # directional light of sun

@onready var moonLight := $MoonLight # directional light of moon

# the sky shader material
var mat: ShaderMaterial
var top = Vector3(0.0, 1.0, 0.0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("readying..")
	time = 0.5
	moon_time = 0.5
	sunLight.rotation = Vector3(0,0,0)
	moonLight.rotation = Vector3(0,0,0)
	_resolve_sky_material()
	_update_atmosphere()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !paused:
		_update_clock(delta)
	_resolve_sky_material()
	_update_sun_moon()
	_update_atmosphere()
	_update_exposure()

func _resolve_sky_material() -> void:
	if sky_material:
		mat = sky_material
	if not environment: # if environment is not set
		return
	var sky = environment.environment.sky
	if sky and sky.sky_material is ShaderMaterial:
		mat = sky.sky_material

func _update_clock(delta: float) -> void:
	var time_change = delta / day_length
	time += time_change if time < 1.0 else -1.0
	moon_time += time_change / moon_length if moon_time < 1.0 else -1.0

func _update_sun_moon(): 
	if !sunLight or !moonLight: return
	var sun_angle = TAU * time
	sunLight.rotation.x = sun_angle
	var sun_tilt = 34.5
	sunLight.rotation.y = sun_tilt
	var moon_angle = sun_angle + TAU * moon_time
	moonLight.rotation.x = moon_angle
	var moon_tilt = 39.5
	moonLight.rotation.y = moon_tilt

# should have exposure be ~20 around noon, but drop off as we reach sunset
# will be implemented here in the script
func _update_exposure() -> void:
	var sun_dir = _get_light_dir(sunLight)
	var how_horizon = clamp(sun_dir.dot(-top), 0.0, 1.0)
	var exposure = lerp(10.0, 20.0, how_horizon)
	mat.set_shader_parameter("exposure", exposure)

func _update_atmosphere() -> void:
	if not mat:
		return
	# normalize to 0..1 as needed
	var hu: float = clamp(humidity, 0, 1)
	# 0..500 to 0..1
	var aq: float = clamp(aqi / 500, 0, 1)
	# 0..50 to 1..0
	var vi: float = clamp((50 - visibility_km) / 50, 0, 1)
	# -35..45 to 0..1
	var te: float = clamp((temperature_c + 35) / 80, 0, 1)
	# 150..450 to 0..1
	var oz: float = clamp((ozone_du - 150) / 300, 0, 1)
	# aqi
	# affects rayleigh, mie, mie g, density
	# aqi 500 ~ 8.0, 8.0, 0.80, 3.0
	# aqi low ~ 1.0, 1.0, 0.85, 1.0 (no effect)
	var aq_curve := pow(aq, 1.67)
	# temperature
	# affects rayleigh, mie, mie g, ozone
	# high ~ 1.2, 8.0, 0.6, 1.0
	# low ~ 0.9, 0.4, 0.89, 4.0
	var te_curve := te
	# humidity
	# mostly the same (?) as temperature
	# affects mie, mie g
	# high ~ 2.0, 0.7
	# low ~ 0.9, 0.49
	var hu_curve := smoothstep(0.3, 1.0, hu)
	# visibility is just fog
	var vi_curve := smoothstep(0.7, 1.0, vi)
	# ozone
	# well, affects ozone
	var oz_curve := pow(oz, 10.0)
	# affected mostly by aqi and a little by temp
	var r_aq: float = lerp(1.0, 8.0, aq_curve)
	var r_te: float = lerp(0.9, 1.2, te_curve)
	var rayleigh_strength: float = r_aq * r_te
	rayleigh_strength = clamp(rayleigh_strength, 0.3, 8.0)
	# affected mostly by aqi and temp, a bit humidity
	var m_aq: float = lerp(1.0, 8.0, aq_curve)
	var m_te: float = lerp(0.4, 8.0, te_curve)
	var m_hu: float = lerp(0.9, 2.0, hu_curve)
	var mie_strength: float = m_aq * m_te * m_hu
	rayleigh_strength = clamp(rayleigh_strength, 0.3, 8.0)
	# affected by aqi, temp, humidity
	var g_aq: float = lerp(0.87/0.85, 0.80/0.85, aq_curve)
	var g_te: float = lerp(0.89/0.85, 0.60/0.85, te_curve)
	var g_hu: float = lerp(0.49/0.85, 0.70/0.85, hu_curve)
	var mie_g: float = 0.85 * g_aq * g_te * g_hu
	mie_g = clamp(mie_g, 0.48, 0.92)
	# affected mostly by ozone, then temp
	var o_te: float = lerp(1.0, 4.0, te_curve)
	var o_oz: float = lerp(0.2, 5.0, oz_curve)
	var ozone_strength: float = o_te * o_oz
	ozone_strength = clamp(ozone_strength, 0.2, 5.0)
	# affected by aqi
	var d_aq: float = lerp(1.0, 3.0, aq_curve)
	var d_te: float = lerp(1.5, 0.5, te_curve)
	var atm_density: float = d_aq * d_te
	# affected by visibility
	var fa_vi: float = lerp(0.0, 0.6, vi_curve)
	var fp_vi: float = lerp(0.0, 6.0, vi_curve)
	var fd_vi: float = lerp(1.5, 4.0, vi_curve)
	var fog_amount: float = fa_vi
	var fog_power: float = fp_vi
	var fog_density: float = fd_vi
	# update shader now
	mat.set_shader_parameter("camera_altitude", camera_altitude)
	mat.set_shader_parameter("rayleigh_strength", rayleigh_strength)
	mat.set_shader_parameter("mie_strength", mie_strength)
	mat.set_shader_parameter("mie_g", mie_g)
	mat.set_shader_parameter("ozone_strength", ozone_strength)
	mat.set_shader_parameter("atm_density", atm_density)
	mat.set_shader_parameter("fog_amount", fog_amount)
	mat.set_shader_parameter("fog_horizon_power", fog_power)
	mat.set_shader_parameter("fog_density", fog_density)

func _get_light_dir(light: DirectionalLight3D) -> Vector3:
	return (-light.global_transform.basis.z).normalized()
