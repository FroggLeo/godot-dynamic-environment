extends CanvasLayer

@export var env := Node3D

@onready var pause := %pause
@onready var pause_v := %vpause

@onready var time := %time
@onready var time_v := %vtime

@onready var humidity := %humidity
@onready var humidity_v := %vhumidity

@onready var aqi := %aqi
@onready var aqi_v := %vaqi

@onready var temp := %temp
@onready var temp_v := %vtemp

@onready var visibility := %vis
@onready var visibility_v := %vvis

@onready var ozone := %ozone
@onready var ozone_v := %vozone

@onready var altitude := %altitude
@onready var altitude_v := %valtitude

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !env: 
		print("noooooooo")
		return
	if "paused" in env:
		print("pause good")
		pause.button_pressed = env.paused
		pause.toggled.connect(func(v): env.paused = v)
	if "time" in env:
		print("time good")
		time.value = env.time
		time.value_changed.connect(func(v): env.time = v)
	if "humidity" in env:
		print("humidity good")
		humidity.value = env.humidity
		humidity.value_changed.connect(func(v): env.humidity = v)
	if "aqi" in env:
		print("aqi good")
		aqi.value = env.aqi
		aqi.value_changed.connect(func(v): env.aqi = v)
	if "visibility_km" in env:
		print("visibility good")
		visibility.value = env.visibility_km
		visibility.value_changed.connect(func(v): env.visibility_km = v)
	if "temperature_c" in env:
		print("temp good")
		temp.value = env.temperature_c
		temp.value_changed.connect(func(v): env.temperature_c = v)
	if "ozone_du" in env:
		print("ozone good")
		ozone.value = env.ozone_du
		ozone.value_changed.connect(func(v): env.ozone_du = v)
	if "camera_altitude" in env:
		print("altitude good")
		altitude.value = env.camera_altitude
		altitude.value_changed.connect(func(v): env.camera_altitude = v)
	

# quick custom clock function
func time_to_24h(envtime: float) -> String:
	var total_minutes := int(envtime * 24 * 60 + 18 * 60) % (24 * 60)
	var hours := int(total_minutes / 60.0)
	var minutes := total_minutes % 60
	return str(hours) + ":" + str(minutes)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if "time" in env and "paused" in env:
		if pause.button_pressed:
			time.editable = true
			pause_v.text = "Paused"
		else:
			time.editable = false
			time.value = env.time
			pause_v.text = "Pause"
	if "time" in env:
		time_v.text = str(time_to_24h(env.time))
