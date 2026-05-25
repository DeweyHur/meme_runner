extends Node2D

@export var obstacle_scene: PackedScene
@export var spawn_distance = 800.0
@export var min_spawn_time = 2.0
@export var max_spawn_time = 4.5

var score = 0
var bonus_score = 0
var game_speed = 1.0
var player_position = 0.0

var life = 150.0
var life_timer = 0.0
var life_decrement_on_hit = 3.0

# Enemy spawning
var turret_scene = preload("res://Enemies/Turret/turret.tscn")
var turret_spawn_timer = 0.0
var turret_spawn_interval = 6.0
var turret_spawn_distance = 600.0

var soldier_script = preload("res://Enemies/GroundSoldier/ground_soldier.gd")
var soldier_spawn_timer = 0.0
var soldier_spawn_interval = 14.0

var bomber_script = preload("res://Enemies/SuicideBomber/suicide_bomber.gd")
var bomber_spawn_timer = 0.0
var bomber_spawn_interval = 40.0

# Item spawning
var item_spawn_timer = 0.0
var item_spawn_interval = 1.8

# Combo system
var combo_count = 0
var combo_timer_val = 0.0
var combo_reset_time = 3.0

# Camera shake
var camera_trauma = 0.0

# Obstacle gap enforcement
var last_obstacle_x = -9999.0

# Floating text
var floating_text_script = preload("res://scripts/FloatingText.gd")

# Stage manager
@onready var stage_manager: Node = $StageManager

var is_game_over = false

var boss_spawned = false
var boss_active = false
var boss_alarm_shown = false
var boss: Node2D = null
var boss_alarm_timer = 0.0
var boss_alarm_duration = 3.0

@onready var player = $Player
var selected_character_path: String = "res://Player/tung.tscn"
@onready var obstacle_spawner = $ObstacleSpawner
@onready var obstacle_timer = $ObstacleSpawner/ObstacleTimer
@onready var score_label = $UI/ScoreLabel
@onready var life_label = $UI/LifeLabel
@onready var stage_label = $UI/StageLabel
@onready var instructions = $UI/Instructions
@onready var procedural_ground = $ProceduralGround
@onready var camera = $Camera2D
@onready var boss_hp_bar = $UI/BossHPBar
@onready var boss_alarm = $UI/BossAlarm
@onready var stage_popup = $UI/StagePopup

var combo_label: Label
var powerup_label: Label

func _ready():
	add_to_group("game_node")

	if get_tree().has_meta("selected_character"):
		selected_character_path = get_tree().get_meta("selected_character")
		get_tree().set_meta("selected_character", null)

	replace_player_with_selected_character()

	# Set initial camera Y so player is visible from the start
	if camera and player:
		camera.position.y = player.position.y - 230.0

	obstacle_timer.timeout.connect(_on_obstacle_timer_timeout)

	update_life_display()

	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(_hide_instructions)
	timer.start()

	if stage_manager:
		stage_manager.stage_changed.connect(_on_stage_changed)
		stage_manager.stage_completed.connect(_on_stage_manager_completed)

	if stage_popup:
		stage_popup.stage_completed.connect(_on_stage_completed)
		stage_popup.game_completed.connect(_on_game_completed)
		stage_popup.show_stage_popup(1, false)
		var stage_timer = Timer.new()
		add_child(stage_timer)
		stage_timer.wait_time = 3.0
		stage_timer.one_shot = true
		stage_timer.timeout.connect(func():
			if stage_popup:
				stage_popup.visible = false
		)
		stage_timer.start()

	# Dynamic HUD elements
	combo_label = Label.new()
	combo_label.name = "ComboLabel"
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.add_theme_font_size_override("font_size", 32)
	combo_label.add_theme_color_override("font_color", Color.YELLOW)
	combo_label.position = Vector2(280, 55)
	combo_label.custom_minimum_size = Vector2(200, 50)
	combo_label.visible = false
	$UI.add_child(combo_label)

	powerup_label = Label.new()
	powerup_label.name = "PowerupLabel"
	powerup_label.add_theme_font_size_override("font_size", 16)
	powerup_label.add_theme_color_override("font_color", Color.CYAN)
	powerup_label.position = Vector2(10, 100)
	powerup_label.custom_minimum_size = Vector2(300, 30)
	$UI.add_child(powerup_label)

func _process(delta):
	life_timer += delta
	if life_timer >= 1.0:
		life -= 0.3
		life_timer = 0.0
		update_life_display()
		if life <= 0:
			life = 0
			update_life_display()
			game_over()
			return

	if player:
		var dist_score = int(player.position.x / 2)
		score = dist_score + bonus_score
		score_label.text = "Score: " + str(score)

		if stage_label and stage_manager:
			var stage_data = stage_manager.get_current_stage_data()
			if stage_data.has("name"):
				stage_label.text = "Stage: " + stage_data["name"]
			else:
				stage_label.text = "Stage: " + str(stage_manager.get_current_stage_number())

		game_speed = 1.0 + (dist_score / 3000.0)
		player.run_speed = 270.0 * game_speed

		if camera:
			camera.position.x = player.position.x
			camera.position.y = lerp(camera.position.y, player.position.y - 230.0, 0.15)

	if is_game_over:
		return

	# Camera shake decay
	if camera_trauma > 0:
		camera_trauma = max(0.0, camera_trauma - delta * 2.0)
		var shake = camera_trauma * camera_trauma * 10.0
		if camera:
			camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	elif camera:
		camera.offset = Vector2.ZERO

	# Coin/health spawning only
	item_spawn_timer += delta
	if item_spawn_timer >= item_spawn_interval:
		spawn_simple_item()
		item_spawn_timer = 0.0
		item_spawn_interval = randf_range(1.2, 2.5)

func _update_powerup_label():
	if not player or not powerup_label:
		return
	var parts = []
	if player.shield_count > 0:
		parts.append("SHIELD x%d" % player.shield_count)
	if player.speed_boost_timer > 0:
		parts.append("SPEED %.1fs" % player.speed_boost_timer)
	if player.rapid_fire_timer > 0:
		parts.append("RAPID %.1fs" % player.rapid_fire_timer)
	powerup_label.text = " | ".join(parts)

# ---- Enemy kill / combo ----

func enemy_killed(type: String, kill_pos: Vector2):
	combo_count += 1
	combo_timer_val = 0.0

	var multiplier = min(combo_count, 8)
	var base_pts = {"soldier": 100, "bomber": 300, "turret": 150, "drone": 200}.get(type, 100)
	var pts = base_pts * multiplier
	bonus_score += pts

	if multiplier > 1:
		combo_label.visible = true
		combo_label.text = "COMBO x%d!" % multiplier
		var col = Color.YELLOW
		if multiplier >= 6:
			col = Color.RED
		elif multiplier >= 4:
			col = Color.ORANGE
		combo_label.add_theme_color_override("font_color", col)

	var label_text = "+%d" % pts
	if multiplier > 1:
		label_text += " x%d!" % multiplier
	spawn_floating_text(label_text, kill_pos, Color.YELLOW)
	camera_shake(0.15 + 0.1 * min(multiplier, 4))

# ---- Item pickup ----

func pickup_item(type: String, world_pos: Vector2):
	match type:
		"coin":
			var pts = 100 * max(1, combo_count)
			bonus_score += pts
			spawn_floating_text("+%d" % pts, world_pos, Color(1.0, 0.9, 0.0))
		"health":
			life = min(150.0, life + 30.0)
			update_life_display()
			spawn_floating_text("+30 HP", world_pos, Color(0.2, 1.0, 0.3))
		"shield":
			if player and player.has_method("activate_shield"):
				player.activate_shield()
			spawn_floating_text("SHIELD!", world_pos, Color.CYAN)
		"speed":
			if player and player.has_method("activate_speed_boost"):
				player.activate_speed_boost()
			spawn_floating_text("SPEED BOOST!", world_pos, Color.YELLOW)
		"rapid_fire":
			if player and player.has_method("activate_rapid_fire"):
				player.activate_rapid_fire()
			spawn_floating_text("RAPID FIRE!", world_pos, Color(1.0, 0.6, 0.1))
	camera_shake(0.06)

func heal_player(amount: float):
	life = min(150.0, life + amount)
	update_life_display()

# ---- Spawning helpers ----

func spawn_random_item():
	if not player:
		return
	var spawn_x = player.position.x + randf_range(350, 750)
	var ground_info = get_ground_info_at_position(spawn_x)
	var ground_y = ground_info.height if ground_info.get("height", -1) != -1 else 500.0

	var roll = randf()
	var item_type: String
	if roll < 0.55:
		item_type = "coin"
	elif roll < 0.75:
		item_type = "health"
	elif roll < 0.85:
		item_type = "shield"
	elif roll < 0.93:
		item_type = "speed"
	else:
		item_type = "rapid_fire"

	spawn_item(item_type, spawn_x, ground_y)

	# Bonus coin clusters
	if item_type == "coin" and randf() < 0.45:
		var count = randi_range(2, 4)
		for i in range(1, count + 1):
			spawn_item("coin", spawn_x + i * 65.0, ground_y)

func spawn_item(type: String, world_x: float, ground_y: float):
	var item = Area2D.new()
	item.add_to_group("items")
	item.collision_mask = 1
	item.collision_layer = 0

	var body_colors = {
		"coin":       Color(1.0, 0.85, 0.0),
		"health":     Color(0.05, 0.82, 0.15),
		"shield":     Color(0.15, 0.55, 1.0),
		"speed":      Color(1.0, 0.95, 0.1),
		"rapid_fire": Color(1.0, 0.35, 0.05)
	}
	var icons = {"coin": "$", "health": "+", "shield": "O", "speed": ">>", "rapid_fire": "!"}
	var names_map = {"coin": "COIN", "health": "HEAL", "shield": "SHIELD", "speed": "SPEED", "rapid_fire": "RAPID"}

	var sz = 36.0
	var main_color = body_colors.get(type, Color.WHITE)

	# Dark outline
	var outline = ColorRect.new()
	outline.size = Vector2(sz + 6, sz + 6)
	outline.position = Vector2(-sz * 0.5 - 3, -sz - 3)
	outline.color = Color(0.0, 0.0, 0.0)
	item.add_child(outline)

	# Inner highlight
	var highlight = ColorRect.new()
	highlight.size = Vector2(sz, sz)
	highlight.position = Vector2(-sz * 0.5, -sz)
	highlight.color = main_color.lightened(0.3)
	item.add_child(highlight)

	# Main body
	var bg = ColorRect.new()
	bg.size = Vector2(sz - 4, sz - 4)
	bg.position = Vector2(-sz * 0.5 + 2, -sz + 2)
	bg.color = main_color
	item.add_child(bg)

	# Icon symbol
	var icon_lbl = Label.new()
	icon_lbl.text = icons.get(type, "?")
	icon_lbl.add_theme_font_size_override("font_size", 22)
	icon_lbl.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.position = Vector2(-sz * 0.5, -sz)
	icon_lbl.custom_minimum_size = Vector2(sz, sz)
	item.add_child(icon_lbl)

	# Name label above the item
	var name_bg = ColorRect.new()
	name_bg.size = Vector2(68, 22)
	name_bg.position = Vector2(-34, -sz - 26)
	name_bg.color = Color(0.0, 0.0, 0.0, 0.7)
	item.add_child(name_bg)
	var name_lbl = Label.new()
	name_lbl.text = names_map.get(type, type.to_upper())
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", main_color.lightened(0.2))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position = Vector2(-34, -sz - 26)
	name_lbl.custom_minimum_size = Vector2(68, 22)
	item.add_child(name_lbl)

	# Collision (larger radius = easier to pick up)
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 26.0
	col.shape = shape
	col.position = Vector2(0, -sz * 0.5)
	item.add_child(col)

	item.set_meta("pickup_type", type)
	item.set_meta("collected", false)
	item.position = Vector2(world_x, ground_y - 46)

	item.body_entered.connect(func(body):
		if is_instance_valid(item) and not item.get_meta("collected", false):
			if body.is_in_group("player"):
				item.set_meta("collected", true)
				pickup_item(item.get_meta("pickup_type"), item.global_position)
				item.queue_free()
	)

	add_child(item)

	# Float animation (must be after add_child)
	var base_y = item.position.y
	var tween = item.create_tween()
	tween.set_loops()
	tween.tween_property(item, "position:y", base_y - 10, 0.7).set_trans(Tween.TRANS_SINE)
	tween.tween_property(item, "position:y", base_y, 0.7).set_trans(Tween.TRANS_SINE)

	var cleanup = Timer.new()
	item.add_child(cleanup)
	cleanup.wait_time = 12.0
	cleanup.one_shot = true
	cleanup.timeout.connect(func():
		if is_instance_valid(item):
			item.queue_free()
	)
	cleanup.start()

func spawn_simple_item():
	if not player:
		return
	var spawn_x = player.position.x + randf_range(400, 800)
	var ground_info = get_ground_info_at_position(spawn_x)
	var ground_y = ground_info.get("height", 500.0)
	if ground_y == -1:
		ground_y = 500.0

	var roll = randf()
	if roll < 0.75:
		# Coin cluster
		var count = randi_range(3, 6)
		for i in count:
			spawn_item("coin", spawn_x + i * 55.0, ground_y)
	else:
		# Health pack
		spawn_item("health", spawn_x, ground_y)

func spawn_ground_soldiers():
	if not player:
		return
	var count = 1
	if game_speed >= 1.5:
		count = 2
	if game_speed >= 2.0:
		count = randi_range(2, 3)

	for i in count:
		var spawn_x = player.position.x + randf_range(500, 850) + i * 90.0
		var ground_info = get_ground_info_at_position(spawn_x)
		var ground_y = ground_info.get("height", 500.0)
		if ground_y == -1:
			ground_y = 500.0

		var soldier = soldier_script.new()
		soldier.position = Vector2(spawn_x, ground_y - 20)
		add_child(soldier)
		soldier.speed = 130.0 + (game_speed - 1.0) * 50.0

func spawn_suicide_bomber():
	if not player:
		return
	var spawn_x = player.position.x + randf_range(650, 950)
	var ground_info = get_ground_info_at_position(spawn_x)
	var ground_y = ground_info.get("height", 500.0)
	if ground_y == -1:
		ground_y = 500.0

	var bomber = bomber_script.new()
	bomber.position = Vector2(spawn_x, ground_y - 20)
	add_child(bomber)

func spawn_floating_text(text: String, world_pos: Vector2, color: Color):
	var ft = floating_text_script.new()
	add_child(ft)
	ft.global_position = world_pos + Vector2(0, -50)
	ft.setup(text, color)

func camera_shake(trauma: float):
	camera_trauma = min(1.0, camera_trauma + trauma)

# ---- Obstacle spawning (re-enabled) ----

func _on_obstacle_timer_timeout():
	if not is_game_over and player:
		var spawn_x = player.position.x + spawn_distance
		if spawn_x - last_obstacle_x >= 700.0:
			var ground_info = get_ground_info_at_position(spawn_x)
			var ground_y = ground_info.get("height", 500.0)
			if ground_y == -1:
				ground_y = 500.0
			create_obstacle_at(spawn_x, ground_y)
			last_obstacle_x = spawn_x
	obstacle_timer.wait_time = randf_range(min_spawn_time, max_spawn_time)

func _make_label(text: String, color: Color, size: int, w: float, ox: float, oy: float) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(ox - w * 0.5, oy)
	lbl.custom_minimum_size = Vector2(w, size + 8)
	return lbl

func create_obstacle_at(x: float, ground_y: float):
	var obstacle = StaticBody2D.new()
	obstacle.add_to_group("obstacles")

	var obstacle_type = randi() % 2  # Only 2 types: jump wall and duck bar

	match obstacle_type:
		0:  # ===== JUMP WALL =====
			var wall_w = 50.0
			var wall_h = 120.0

			# Dark outline behind wall
			var outline = ColorRect.new()
			outline.size = Vector2(wall_w + 6, wall_h + 6)
			outline.position = Vector2(-wall_w * 0.5 - 3, -wall_h - 3)
			outline.color = Color(0.0, 0.0, 0.0)
			obstacle.add_child(outline)

			# Main red wall
			var rect = ColorRect.new()
			rect.size = Vector2(wall_w, wall_h)
			rect.position = Vector2(-wall_w * 0.5, -wall_h)
			rect.color = Color(0.95, 0.15, 0.1)
			obstacle.add_child(rect)

			# Yellow warning stripes
			for i in 3:
				var stripe = ColorRect.new()
				stripe.size = Vector2(wall_w, 10)
				stripe.position = Vector2(-wall_w * 0.5, -wall_h + 14 + i * 24)
				stripe.color = Color(1.0, 0.9, 0.0, 0.5)
				obstacle.add_child(stripe)

			# "JUMP!" label above wall
			var bg_lbl = ColorRect.new()
			bg_lbl.size = Vector2(80, 30)
			bg_lbl.position = Vector2(-40, -wall_h - 36)
			bg_lbl.color = Color(1.0, 0.9, 0.0)
			obstacle.add_child(bg_lbl)
			obstacle.add_child(_make_label("JUMP!", Color.BLACK, 20, 80, 0, -wall_h - 35))

			# Collision
			var col = CollisionShape2D.new()
			var shape = RectangleShape2D.new()
			shape.size = Vector2(wall_w, wall_h)
			col.shape = shape
			col.position = Vector2(0, -wall_h * 0.5)
			obstacle.add_child(col)

		1:  # ===== DUCK BAR =====
			var bar_w = 120.0
			var bar_h = 28.0
			var bar_y = -40.0  # center Y; bar bottom at -26 from ground — blocks standing (top=-43), passes crouching (top=-22)

			# Dark outline
			var outline = ColorRect.new()
			outline.size = Vector2(bar_w + 6, bar_h + 6)
			outline.position = Vector2(-bar_w * 0.5 - 3, bar_y - bar_h * 0.5 - 3)
			outline.color = Color(0.0, 0.0, 0.0)
			obstacle.add_child(outline)

			# Main bar
			var rect = ColorRect.new()
			rect.size = Vector2(bar_w, bar_h)
			rect.position = Vector2(-bar_w * 0.5, bar_y - bar_h * 0.5)
			rect.color = Color(0.1, 0.5, 1.0)
			obstacle.add_child(rect)

			# Chevron stripes on bar
			for i in 4:
				var stripe = ColorRect.new()
				stripe.size = Vector2(12, bar_h)
				stripe.position = Vector2(-bar_w * 0.5 + 14 + i * 26, bar_y - bar_h * 0.5)
				stripe.color = Color(0.5, 0.8, 1.0, 0.6)
				obstacle.add_child(stripe)

			# Support pillars (visual only) — from bar bottom to ground
			for side in [-1, 1]:
				var pillar = ColorRect.new()
				var pillar_top = bar_y + bar_h * 0.5
				pillar.size = Vector2(10, abs(pillar_top))
				pillar.position = Vector2(side * (bar_w * 0.5 - 5), pillar_top)
				pillar.color = Color(0.05, 0.35, 0.75)
				obstacle.add_child(pillar)

			# "DUCK!" label above the bar
			var bg_lbl = ColorRect.new()
			bg_lbl.size = Vector2(80, 28)
			bg_lbl.position = Vector2(-40, bar_y - bar_h * 0.5 - 34)
			bg_lbl.color = Color(0.1, 0.5, 1.0)
			obstacle.add_child(bg_lbl)
			obstacle.add_child(_make_label("DUCK!", Color.WHITE, 18, 80, 0, bar_y - bar_h * 0.5 - 33))

			# Collision
			var col = CollisionShape2D.new()
			var shape = RectangleShape2D.new()
			shape.size = Vector2(bar_w, bar_h)
			col.shape = shape
			col.position = Vector2(0, bar_y)
			obstacle.add_child(col)

	obstacle.position = Vector2(x, ground_y)
	obstacle_spawner.add_child(obstacle)

	var cleanup = Timer.new()
	obstacle.add_child(cleanup)
	cleanup.wait_time = 14.0
	cleanup.one_shot = true
	cleanup.timeout.connect(func():
		if is_instance_valid(obstacle):
			obstacle.queue_free()
	)
	cleanup.start()

# ---- Turret spawning ----

func spawn_turret():
	if not turret_scene or not player:
		return
	var spawn_x = player.position.x + turret_spawn_distance
	var ground_info = get_ground_info_at_position(spawn_x)
	if ground_info.get("height", -1) == -1:
		return
	var turret = turret_scene.instantiate()
	add_child(turret)
	turret.global_position = Vector2(spawn_x, ground_info.height - 60)
	var cleanup_timer = Timer.new()
	turret.add_child(cleanup_timer)
	cleanup_timer.wait_time = 15.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): turret.queue_free())
	cleanup_timer.start()

# ---- Ground queries ----

func get_ground_height_at_position(x_position: float) -> float:
	if procedural_ground:
		return get_ground_height_from_procedural_ground(x_position)
	return 500.0

func get_ground_info_at_position(x_position: float) -> Dictionary:
	if procedural_ground and procedural_ground.has_method("get_ground_info_at"):
		return procedural_ground.get_ground_info_at(x_position)
	return {"height": 500.0, "normal": Vector2.UP}

func get_ground_height_from_procedural_ground(x_position: float) -> float:
	if procedural_ground and procedural_ground.has_method("get_ground_height_at"):
		return procedural_ground.get_ground_height_at(x_position)
	return 500.0

# ---- Boss ----

func show_boss_alarm():
	if boss_alarm_shown or not boss_alarm:
		return
	boss_alarm_shown = true
	boss_alarm_timer = 0.0
	boss_alarm.show_boss_alarm()

func spawn_boss():
	if boss_spawned or not stage_manager:
		return
	var current_stage_instance = stage_manager.get_current_stage()
	if not current_stage_instance or not current_stage_instance.has_method("spawn_boss"):
		return
	boss_spawned = true
	if boss_alarm:
		boss_alarm.hide_boss_alarm()
	var spawned_boss = current_stage_instance.spawn_boss()
	if spawned_boss:
		boss_active = true
		if boss_hp_bar:
			boss_hp_bar.set_boss(spawned_boss)

func boss_defeated():
	# Called when boss dies (forwarded from Stage or directly)
	boss_active = false
	if boss_hp_bar:
		boss_hp_bar.hide_hp_bar()
	bonus_score += 1000
	camera_shake(0.6)
	spawn_floating_text("BOSS DEFEATED! +1000", Vector2(camera.position.x, 300), Color.RED)
	# Show stage completion popup
	if stage_popup and stage_manager:
		stage_popup.show_stage_popup(stage_manager.get_current_stage_number(), true)

# ---- Damage / life ----

func player_took_damage(amount: float = 3.0):
	life -= amount
	camera_shake(0.3)
	update_life_display()
	if life <= 0:
		life = 0
		update_life_display()
		game_over()

func _hide_instructions():
	instructions.visible = false

func update_life_display():
	if life_label:
		life_label.text = "HP: %d" % int(life)
		if life > 90:
			life_label.add_theme_color_override("font_color", Color.GREEN)
		elif life > 45:
			life_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			life_label.add_theme_color_override("font_color", Color.RED)

func game_over():
	if is_game_over:
		return
	is_game_over = true
	obstacle_timer.stop()

	var game_over_label = Label.new()
	game_over_label.name = "GameOverLabel"
	game_over_label.text = "Game Over!\nFinal Score: " + str(score) + "\nStage Reached: " + str(stage_manager.get_current_stage_number() if stage_manager else 1) + "\n\nPress SPACE to return to Main Menu"
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.anchors_preset = Control.PRESET_FULL_RECT
	game_over_label.add_theme_font_size_override("font_size", 32)
	game_over_label.add_theme_color_override("font_color", Color.RED)
	$UI.add_child(game_over_label)
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if is_game_over:
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		elif boss_active == false and boss_spawned and not stage_popup.visible:
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func restart_game():
	get_tree().paused = false
	get_tree().reload_current_scene()

# ---- Stage progression ----

func _on_stage_manager_completed(_stage_number: int = 0):
	# Stage completion via signal chain — show the popup
	if stage_popup and stage_manager:
		stage_popup.show_stage_popup(stage_manager.get_current_stage_number(), true)
	boss_active = false
	if boss_hp_bar:
		boss_hp_bar.hide_hp_bar()

func _on_stage_completed():
	if stage_manager and stage_manager.next_stage():
		life = 100.0
		life_timer = 0.0
		update_life_display()

		boss_spawned = false
		boss_active = false
		boss_alarm_shown = false
		boss_alarm_timer = 0.0
		if boss:
			boss.queue_free()
			boss = null

		if boss_alarm:
			boss_alarm.hide_boss_alarm()
		if boss_hp_bar:
			boss_hp_bar.hide_hp_bar()

		clear_stage_enemies()

		if procedural_ground and procedural_ground.has_method("regenerate_world"):
			procedural_ground.regenerate_world()

		replace_player_with_selected_character()

		if stage_popup:
			stage_popup.show_stage_popup(stage_manager.get_current_stage_number(), false)
	else:
		_on_game_completed()

func _on_stage_changed(stage_data: Dictionary):
	if stage_label:
		stage_label.text = "Stage: " + stage_data["name"]

func clear_stage_enemies():
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node):
			node.queue_free()
	for node in get_tree().get_nodes_in_group("obstacles"):
		if is_instance_valid(node):
			node.queue_free()
	for node in get_tree().get_nodes_in_group("items"):
		if is_instance_valid(node):
			node.queue_free()

func _on_game_completed():
	show_victory_screen()

func show_victory_screen():
	turret_spawn_timer = 999999.0

	var victory_container = Control.new()
	victory_container.name = "VictoryScreen"
	victory_container.anchors_preset = Control.PRESET_FULL_RECT

	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.8)
	background.anchors_preset = Control.PRESET_FULL_RECT
	victory_container.add_child(background)

	var victory_label = Label.new()
	victory_label.text = "VICTORY!\n\nAll Stages Cleared!\nFinal Score: " + str(score) + "\nLife Remaining: " + str(int(life)) + "\n\nPress SPACE to return to Main Menu"
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory_label.anchors_preset = Control.PRESET_FULL_RECT
	victory_label.add_theme_font_size_override("font_size", 32)
	victory_label.add_theme_color_override("font_color", Color.WHITE)
	victory_container.add_child(victory_label)

	$UI.add_child(victory_container)
	set_process_input(true)

func replace_player_with_selected_character():
	if player:
		var player_pos = player.position
		player.queue_free()
		var character_scene = load(selected_character_path)
		if character_scene:
			player = character_scene.instantiate()
			player.position = player_pos
			add_child(player)
