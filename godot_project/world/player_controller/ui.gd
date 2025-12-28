extends CanvasLayer

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
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
