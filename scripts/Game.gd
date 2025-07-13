extends Node2D

@export var obstacle_scene: PackedScene
@export var spawn_distance = 800.0
@export var min_spawn_time = 1.0
@export var max_spawn_time = 3.0

var score = 0
var game_speed = 1.0
var player_position = 0.0

# Life system variables
var life = 100.0  # Start with 100 seconds of life
var life_timer = 0.0  # Timer to track seconds
var life_decrement_on_hit = 5.0  # Life lost when hit

# Turret spawning variables
var turret_scene = preload("res://Enemies/Turret/turret.tscn")
var turret_spawn_timer = 0.0
var turret_spawn_interval = 5.0  # Spawn turret every 5 seconds
var turret_spawn_distance = 600.0  # Distance ahead of player to spawn turrets

# Stage system variables
var current_stage = 1
var total_stages = 3
var stage_start_distance = 0.0
var stage_boss_distance = 5000.0  # Distance to spawn boss for each stage
var stage_boss_alarm_distance = 4500.0  # Distance to show alarm before boss

# Game state variables
var is_game_over = false

# Boss battle variables
var boss_scene = preload("res://Enemies/Drone/drone.tscn")  # We'll modify this to use boss script
var boss_spawned = false
var boss_active = false
var boss_alarm_shown = false
var boss: Node2D = null

@onready var player = $Player
var selected_character_path: String = "res://Player/tung.tscn"  # Default character
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

func _ready():
	# Check if we have a character selection from the previous scene
	if get_tree().has_meta("selected_character"):
		selected_character_path = get_tree().get_meta("selected_character")
		get_tree().set_meta("selected_character", null)  # Clear the meta
	
	# Replace the default player with the selected character
	replace_player_with_selected_character()
	
	# Connect timer signal
	obstacle_timer.timeout.connect(_on_obstacle_timer_timeout)
	
	# Initialize life display
	update_life_display()
	
	# Hide instructions after 3 seconds
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(_hide_instructions)
	timer.start()
	
	# Initialize stage popup
	if stage_popup:
		stage_popup.stage_completed.connect(_on_stage_completed)
		stage_popup.game_completed.connect(_on_game_completed)
		stage_popup.show_stage_popup(current_stage, false)
		
		# Hide stage popup after 3 seconds for initial stage
		var stage_timer = Timer.new()
		add_child(stage_timer)
		stage_timer.wait_time = 3.0
		stage_timer.one_shot = true
		stage_timer.timeout.connect(func(): 
			if stage_popup:
				stage_popup.visible = false
		)
		stage_timer.start()

func _process(delta):
	# Update life timer and decrement life every second
	life_timer += delta
	if life_timer >= 1.0:
		life -= 1.0
		life_timer = 0.0
		update_life_display()
		
		# Check if life reached 0
		if life <= 0:
			life = 0
			update_life_display()
			print("Life reached 0, calling game_over()")
			game_over()
			return
	
	# Update score based on distance traveled
	if player:
		score = int(player.position.x / 10)
		score_label.text = "Score: " + str(score)
		
		# Update stage display
		if stage_label:
			stage_label.text = "Stage: " + str(current_stage)
		
		# Increase game speed over time
		game_speed = 1.0 + (score / 1000.0)
		player.run_speed = 300.0 * game_speed
		
		# Update camera to follow player
		if camera:
			camera.position.x = player.position.x
	
	# Handle turret spawning
	turret_spawn_timer += delta
	if turret_spawn_timer >= turret_spawn_interval:
		spawn_turret()
		turret_spawn_timer = 0.0
	
	# Handle boss alarm and spawning for current stage
	var current_boss_alarm_distance = stage_start_distance + stage_boss_alarm_distance
	var current_boss_spawn_distance = stage_start_distance + stage_boss_distance
	
	if not boss_alarm_shown and player.position.x >= current_boss_alarm_distance:
		show_boss_alarm()
		boss_alarm_shown = true
	
	if not boss_spawned and player.position.x >= current_boss_spawn_distance:
		print("Player reached %.0f x position, spawning boss for stage %d!" % [current_boss_spawn_distance, current_stage])
		hide_boss_alarm()
		spawn_boss()

func _on_obstacle_timer_timeout():
	# spawn_obstacle()
	# Randomize next spawn time
	obstacle_timer.wait_time = randf_range(min_spawn_time, max_spawn_time)

func spawn_obstacle():
	if not obstacle_scene:
		# Create a simple obstacle if no scene is provided
		create_simple_obstacle()
	else:
		var obstacle = obstacle_scene.instantiate()
		obstacle_spawner.add_child(obstacle)
		obstacle.position = Vector2(player.position.x + spawn_distance, 500)

func create_simple_obstacle():
	var obstacle = StaticBody2D.new()
	obstacle.add_to_group("obstacles")
	
	# Random obstacle type
	var obstacle_type = randi() % 3
	
	match obstacle_type:
		0:  # High obstacle (jump over)
			var collision = CollisionShape2D.new()
			var shape = RectangleShape2D.new()
			shape.size = Vector2(50, 100)
			collision.shape = shape
			collision.position = Vector2(0, -50)
			obstacle.add_child(collision)
			
			var sprite = ColorRect.new()
			sprite.size = Vector2(50, 100)
			sprite.position = Vector2(-25, -100)
			sprite.color = Color(1, 0, 0, 1)
			obstacle.add_child(sprite)
			
		1:  # Low obstacle (slide under)
			var collision = CollisionShape2D.new()
			var shape = RectangleShape2D.new()
			shape.size = Vector2(100, 50)
			collision.shape = shape
			collision.position = Vector2(0, -25)
			obstacle.add_child(collision)
			
			var sprite = ColorRect.new()
			sprite.size = Vector2(100, 50)
			sprite.position = Vector2(-50, -50)
			sprite.color = Color(1, 0.5, 0, 1)
			obstacle.add_child(sprite)
			
		2:  # Both high and low (need to jump and slide)
			var collision1 = CollisionShape2D.new()
			var shape1 = RectangleShape2D.new()
			shape1.size = Vector2(50, 100)
			collision1.shape = shape1
			collision1.position = Vector2(-25, -50)
			obstacle.add_child(collision1)
			
			var collision2 = CollisionShape2D.new()
			var shape2 = RectangleShape2D.new()
			shape2.size = Vector2(50, 100)
			collision2.shape = shape2
			collision2.position = Vector2(25, -50)
			obstacle.add_child(collision2)
			
			var sprite1 = ColorRect.new()
			sprite1.size = Vector2(50, 100)
			sprite1.position = Vector2(-50, -100)
			sprite1.color = Color(1, 0, 0, 1)
			obstacle.add_child(sprite1)
			
			var sprite2 = ColorRect.new()
			sprite2.size = Vector2(50, 100)
			sprite2.position = Vector2(0, -100)
			sprite2.color = Color(1, 0, 0, 1)
			obstacle.add_child(sprite2)
	
	obstacle.position = Vector2(player.position.x + spawn_distance, 500)
	obstacle_spawner.add_child(obstacle)
	
	# Add a timer to remove obstacles that are far behind
	var cleanup_timer = Timer.new()
	obstacle.add_child(cleanup_timer)
	cleanup_timer.wait_time = 10.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): obstacle.queue_free())
	cleanup_timer.start()

func _hide_instructions():
	instructions.visible = false

func game_over():
	if is_game_over:
		return  # Prevent multiple game over calls
	
	is_game_over = true
	
	# Stop spawning obstacles
	obstacle_timer.stop()
	
	# Show game over screen
	var game_over_label = Label.new()
	game_over_label.name = "GameOverLabel"
	game_over_label.text = "Game Over!\nFinal Score: " + str(score) + "\nStage Reached: " + str(current_stage) + "\nPress SPACE to return to Main Menu"
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.anchors_preset = Control.PRESET_FULL_RECT
	game_over_label.add_theme_font_size_override("font_size", 32)
	game_over_label.add_theme_color_override("font_color", Color.RED)
	
	$UI.add_child(game_over_label)
	
	# Listen for input to return to main menu
	set_process_input(true)
	
	print("Game Over! Final Score: %d, Stage Reached: %d" % [score, current_stage])

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if is_game_over:
			print("Game over detected, returning to main menu")
			# Return to main menu on game over
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		elif boss_active == false and boss_spawned and not stage_popup.visible:
			# Return to main menu after victory (legacy support)
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func restart_game():
	get_tree().paused = false
	get_tree().reload_current_scene()

func spawn_turret():
	if not turret_scene or not player:
		return
	
	# Calculate spawn position ahead of player
	var spawn_x = player.position.x + turret_spawn_distance
	
	# Get ground height and normal at spawn position
	var ground_info = get_ground_info_at_position(spawn_x)
	if ground_info.height == -1:
		return  # Couldn't find ground height
	
	# Spawn turret
	var turret = turret_scene.instantiate()
	add_child(turret)
	turret.global_position = Vector2(spawn_x, ground_info.height - 25)  # Position on ground
	
	# Orient turret orthogonal to ground normal
	if ground_info.normal != Vector2.ZERO:
		var ground_angle = ground_info.normal.angle()
		var turret_rotation = ground_angle + PI/2  # Add 90 degrees to be orthogonal
		turret.rotation = turret_rotation
		print("Spawned turret at position: %s with rotation: %.2f° (ground normal: %s)" % [
			turret.global_position, rad_to_deg(turret_rotation), ground_info.normal
		])
	else:
		print("Spawned turret at position: ", turret.global_position)
	
	# Add cleanup timer for turrets
	var cleanup_timer = Timer.new()
	turret.add_child(cleanup_timer)
	cleanup_timer.wait_time = 15.0  # Remove turrets after 15 seconds
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): turret.queue_free())
	cleanup_timer.start()

func get_ground_height_at_position(x_position: float) -> float:
	# Try to find ground height by raycasting or checking procedural ground
	if procedural_ground:
		# Get the ground height from procedural ground
		return get_ground_height_from_procedural_ground(x_position)
	
	# Fallback: use a default height
	return 500.0

func get_ground_info_at_position(x_position: float) -> Dictionary:
	# Get ground height and normal from procedural ground
	if procedural_ground and procedural_ground.has_method("get_ground_info_at"):
		return procedural_ground.get_ground_info_at(x_position)
	
	# Fallback: use default values
	return {"height": 500.0, "normal": Vector2.UP}

func get_ground_height_from_procedural_ground(x_position: float) -> float:
	# Use the procedural ground's get_ground_height_at method
	if procedural_ground and procedural_ground.has_method("get_ground_height_at"):
		return procedural_ground.get_ground_height_at(x_position)
	
	# Fallback: use a default height
	return 500.0

func show_boss_alarm():
	if boss_alarm:
		boss_alarm.show_boss_alarm()
		print("Boss alarm shown at x position: %.0f" % player.position.x)

func hide_boss_alarm():
	if boss_alarm:
		boss_alarm.hide_boss_alarm()

func spawn_boss():
	if boss_spawned or not player:
		return
	
	print("Spawning boss drone!")
	boss_spawned = true
	
	# Create boss drone
	boss = boss_scene.instantiate()
	add_child(boss)
	
	# Position boss at the correct distance from player
	boss.global_position = Vector2(player.position.x + 400, player.position.y - 100)
	print("Boss spawned at position: ", boss.global_position, " (player at: ", player.position, ")")
	
	# Replace the script with boss script
	var boss_script = load("res://Enemies/Drone/boss_drone.gd")
	if boss_script:
		boss.set_script(boss_script)
		boss.activate_boss()
		boss_active = true
		
		# Show boss HP bar
		if boss_hp_bar:
			boss_hp_bar.set_boss(boss)
		
		print("Boss drone activated and ready for battle!")
	else:
		print("Failed to load boss script!")

func boss_defeated():
	print("Boss defeated for stage %d!" % current_stage)
	boss_active = false
	
	# Hide boss HP bar
	if boss_hp_bar:
		boss_hp_bar.hide_hp_bar()
	
	# Show stage popup for completion
	if stage_popup:
		if current_stage < total_stages:
			stage_popup.show_stage_popup(current_stage, true)
		else:
			# Final stage completed
			stage_popup.show_game_completion()

func show_victory_screen():
	# Stop spawning enemies
	turret_spawn_timer = 999999.0  # Disable turret spawning
	
	# Create victory screen
	var victory_container = Control.new()
	victory_container.name = "VictoryScreen"
	victory_container.anchors_preset = Control.PRESET_FULL_RECT
	
	# Victory background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.8)
	background.anchors_preset = Control.PRESET_FULL_RECT
	victory_container.add_child(background)
	
	# Victory label
	var victory_label = Label.new()
	victory_label.text = "VICTORY!\n\nBoss Defeated!\nFinal Score: " + str(score) + "\nLife Remaining: " + str(int(life)) + "\n\nPress SPACE to return to Main Menu"
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory_label.anchors_preset = Control.PRESET_FULL_RECT
	victory_label.add_theme_font_size_override("font_size", 32)
	victory_label.add_theme_color_override("font_color", Color.WHITE)
	victory_container.add_child(victory_label)
	
	$UI.add_child(victory_container)
	
	# Listen for input to return to main menu
	set_process_input(true)

func replace_player_with_selected_character():
	# Remove the default player
	if player:
		var player_position = player.position
		player.queue_free()
		
		# Load and instantiate the selected character
		var character_scene = load(selected_character_path)
		if character_scene:
			player = character_scene.instantiate()
			player.position = player_position
			add_child(player)
		else:
			print("Failed to load character scene: ", selected_character_path) 

func update_life_display():
	if life_label:
		life_label.text = "Life: " + str(int(life))
		
		# Change color based on life remaining
		if life > 60:
			life_label.add_theme_color_override("font_color", Color.GREEN)
		elif life > 30:
			life_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			life_label.add_theme_color_override("font_color", Color.RED)

func player_took_damage():
	# Called when player is hit
	print("Player took damage! Life before: %.1f" % life)
	life -= life_decrement_on_hit
	update_life_display()
	print("Player took damage! Life after: %.1f" % life)
	
	# Check if life reached 0
	if life <= 0:
		life = 0
		update_life_display()
		print("Player life reached 0 from damage, calling game_over()")
		game_over()

func _on_stage_completed():
	# Proceed to next stage
	current_stage += 1
	stage_start_distance = player.position.x
	
	# Reset player life to 100 for new stage
	life = 100.0
	life_timer = 0.0
	update_life_display()
	
	# Reset boss state for new stage
	boss_spawned = false
	boss_active = false
	boss_alarm_shown = false
	if boss:
		boss.queue_free()
		boss = null
	
	# Hide boss HP bar
	if boss_hp_bar:
		boss_hp_bar.hide_hp_bar()
	
	# Clear existing enemies and obstacles
	clear_stage_enemies()
	
	# Regenerate the procedural world for the new stage
	if procedural_ground and procedural_ground.has_method("regenerate_world"):
		procedural_ground.regenerate_world()
	
	# Respawn the character for the new stage
	replace_player_with_selected_character()
	
	# Show stage popup for new stage
	if stage_popup:
		stage_popup.show_stage_popup(current_stage, false)
	
	print("Proceeding to stage %d with regenerated world and fresh character (life: 100)" % current_stage)

func clear_stage_enemies():
	# Clear all turrets
	var turrets = get_tree().get_nodes_in_group("enemies")
	for turret in turrets:
		if turret and is_instance_valid(turret):
			turret.queue_free()
	
	# Clear all obstacles
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	for obstacle in obstacles:
		if obstacle and is_instance_valid(obstacle):
			obstacle.queue_free()
	
	print("Cleared %d enemies and %d obstacles for new stage" % [turrets.size(), obstacles.size()])

func _on_game_completed():
	# Show final victory screen
	show_victory_screen()
