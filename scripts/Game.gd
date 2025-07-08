extends Node2D

@export var obstacle_scene: PackedScene
@export var spawn_distance = 800.0
@export var min_spawn_time = 1.0
@export var max_spawn_time = 3.0

var score = 0
var game_speed = 1.0
var player_position = 0.0

# Turret spawning variables
var turret_scene = preload("res://Enemies/Turret/turret.tscn")
var turret_spawn_timer = 0.0
var turret_spawn_interval = 5.0  # Spawn turret every 5 seconds
var turret_spawn_distance = 600.0  # Distance ahead of player to spawn turrets

@onready var player = $Player
@onready var obstacle_spawner = $ObstacleSpawner
@onready var obstacle_timer = $ObstacleSpawner/ObstacleTimer
@onready var score_label = $UI/ScoreLabel
@onready var instructions = $UI/Instructions
@onready var procedural_ground = $ProceduralGround
@onready var camera = $Camera2D

func _ready():
	# Connect timer signal
	obstacle_timer.timeout.connect(_on_obstacle_timer_timeout)
	
	# Hide instructions after 3 seconds
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(_hide_instructions)
	timer.start()

func _process(delta):
	# Update score based on distance traveled
	if player:
		score = int(player.position.x / 10)
		score_label.text = "Score: " + str(score)
		
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
	# Stop spawning obstacles
	obstacle_timer.stop()
	
	# Show game over screen
	var game_over_label = Label.new()
	game_over_label.text = "Game Over!\nFinal Score: " + str(score) + "\nPress R to restart"
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.anchors_preset = Control.PRESET_FULL_RECT
	game_over_label.add_theme_font_size_override("font_size", 32)
	
	$UI.add_child(game_over_label)
	
	# Listen for restart input
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_accept") and get_tree().paused:
		restart_game()

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
