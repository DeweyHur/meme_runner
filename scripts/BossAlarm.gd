extends Control

@onready var alarm_label = $AlarmLabel
@onready var alarm_background = $AlarmBackground

var is_showing = false
var flash_timer = 0.0
var flash_interval = 0.3  # Flash every 0.3 seconds

func _ready():
	# Start hidden
	visible = false
	is_showing = false

func _process(delta):
	if is_showing:
		# Flash the alarm
		flash_timer += delta
		if flash_timer >= flash_interval:
			flash_timer = 0.0
			if alarm_background:
				alarm_background.modulate = Color.RED if alarm_background.modulate == Color.WHITE else Color.WHITE

func show_boss_alarm():
	visible = true
	is_showing = true
	flash_timer = 0.0
	
	if alarm_label:
		alarm_label.text = "⚠️  BOSS INCOMING! ⚠️"
	
	if alarm_background:
		alarm_background.modulate = Color.RED
	
	print("Boss alarm activated!")

func hide_boss_alarm():
	visible = false
	is_showing = false
	
	if alarm_background:
		alarm_background.modulate = Color.WHITE
	
	print("Boss alarm hidden") 