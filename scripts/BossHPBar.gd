extends Control

@onready var hp_bar = $HPBar
@onready var hp_label = $HPLabel
@onready var boss_name_label = $BossNameLabel

var boss: Node2D = null
var is_visible = false

func _ready():
	# Start hidden
	visible = false
	is_visible = false

func _process(delta):
	if boss and is_instance_valid(boss) and boss.has_method("get_hp_percentage"):
		update_hp_display()
	else:
		# Hide if boss is no longer valid
		hide_hp_bar()

func set_boss(boss_node: Node2D):
	boss = boss_node
	if boss:
		show_hp_bar()
		if boss_name_label:
			boss_name_label.text = "BOSS DRONE"
	else:
		hide_hp_bar()

func update_hp_display():
	if not boss or not is_visible:
		return
	
	var hp_percentage = boss.get_hp_percentage()
	
	# Update HP bar
	if hp_bar:
		hp_bar.value = hp_percentage * 100  # Convert to percentage
	
	# Update HP label
	if hp_label and boss.has_method("get_hp_percentage"):
		var current_hp = boss.current_hp if boss.has_method("get_hp_percentage") else 0
		var max_hp = boss.max_hp if boss.has_method("get_hp_percentage") else 100
		hp_label.text = "HP: %d/%d" % [current_hp, max_hp]
	
	# Change color based on HP
	if hp_bar:
		if hp_percentage > 0.6:
			hp_bar.modulate = Color.GREEN
		elif hp_percentage > 0.3:
			hp_bar.modulate = Color.YELLOW
		else:
			hp_bar.modulate = Color.RED

func show_hp_bar():
	visible = true
	is_visible = true
	print("Boss HP bar shown")

func hide_hp_bar():
	visible = false
	is_visible = false
	print("Boss HP bar hidden") 