extends CanvasLayer

@export var env := Node3D

@onready var reset := %reset

@onready var pause := %pause # the ui toggle/slider itself
@onready var pause_v := %vpause # the value to be displayed
var pause_d # the default value

@onready var time := %time
@onready var time_v := %vtime
var time_d

@onready var daylen := %dayl
@onready var daylen_v := %vdayl
var daylen_d

@onready var humidity := %humidity
@onready var humidity_v := %vhumidity
var humidity_d

@onready var aqi := %aqi
@onready var aqi_v := %vaqi
var aqi_d

@onready var temp := %temp
@onready var temp_v := %vtemp
var temp_d

@onready var visibility := %vis
@onready var visibility_v := %vvis
var visibility_d

@onready var ozone := %ozone
@onready var ozone_v := %vozone
var ozone_d

@onready var altitude := %altitude
@onready var altitude_v := %valtitude
var altitude_d

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !env: 
		print("noooooooo")
		return
	if "paused" in env:
		print("pause good")
		pause_d = env.paused
		pause.button_pressed = pause_d
		pause.toggled.connect(func(v): env.paused = v)
	if "time" in env:
		print("time good")
		time_d = env.time
		time.value = time_d
		time.value_changed.connect(_time_slider_update)
	if "day_length" in env:
		print("daylength good")
		daylen_d = env.day_length
		daylen.value = daylen_d
		daylen.value_changed.connect(func(v): env.day_length = v)
	if "humidity" in env:
		print("humidity good")
		humidity_d = env.humidity
		humidity.value = humidity_d
		humidity.value_changed.connect(func(v): env.humidity = v)
	if "aqi" in env:
		print("aqi good")
		aqi_d = env.aqi
		aqi.value = aqi_d
		aqi.value_changed.connect(func(v): env.aqi = v)
	if "visibility_km" in env:
		print("visibility good")
		visibility_d = env.visibility_km
		visibility.value = visibility_d
		visibility.value_changed.connect(func(v): env.visibility_km = v)
	if "temperature_c" in env:
		print("temp good")
		temp_d = env.temperature_c
		temp.value = temp_d
		temp.value_changed.connect(func(v): env.temperature_c = v)
	if "ozone_du" in env:
		print("ozone good")
		ozone_d = env.ozone_du
		ozone.value = ozone_d
		ozone.value_changed.connect(func(v): env.ozone_du = v)
	if "camera_altitude" in env:
		print("altitude good")
		altitude_d = env.camera_altitude
		altitude.value = altitude_d
		altitude.value_changed.connect(func(v): env.camera_altitude = v)
	reset.pressed.connect(_reset_all_values)

func _reset_all_values():
	pause.button_pressed = pause_d
	time.value = time_d
	if "time" in env:
		env.time = time_d
	daylen.value = daylen_d
	humidity.value = humidity_d
	aqi.value = aqi_d
	visibility.value = visibility_d
	temp.value = temp_d
	ozone.value = ozone_d
	altitude.value = altitude_d

func _time_slider_update(v: float):
	env.time = v

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
			if !time.value_changed.is_connected(_time_slider_update):
				time.value_changed.connect(_time_slider_update)
			time.editable = true
			pause_v.text = "Paused"
		else:
			if time.value_changed.is_connected(_time_slider_update):
				# disconnect the slider so that it doesn't do weird feedback
				time.value_changed.disconnect(_time_slider_update)
			time.editable = false
			time.value = env.time
			pause_v.text = "Pause"
	if "time" in env:
		time_v.text = str(time_to_24h(env.time))
	if "day_length" in env:
		daylen_v.text = str(env.day_length) + "s"
	if "humidity" in env:
		humidity_v.text = str(env.humidity * 100) + "%"
	if "aqi" in env:
		aqi_v.text = str(env.aqi)
	if "visibility_km" in env:
		visibility_v.text = str(env.visibility_km) + "km"
	if "temperature_c" in env:
		temp_v.text = str(env.temperature_c) + "°C"
	if "ozone_du" in env:
		ozone_v.text = str(env.ozone_du) + " DU"
	if "camera_altitude" in env:
		altitude_v.text = str(env.camera_altitude) + "m"
