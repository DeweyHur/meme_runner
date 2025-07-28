extends Node2D

# Stage information
@export var stage_name: String = "Cyberpunk Stage"
@export var stage_description: String = "A neon-lit cityscape with towering skyscrapers and flying cars"
@export var stage_number: int = 2
@export var boss_scene: PackedScene
@export var background_music: AudioStream
@export var difficulty_multiplier: float = 1.2

# Stage-specific variables
var boss_spawned: bool = false
var boss_active: bool = false
var stage_completed: bool = false

# Stage elements
var parallax_background: Node2D
var ground: Node2D
var obstacles: Node2D
var enemies: Node2D
var props: Node2D
var boss_spawn_point: Marker2D

func _ready():
	# Initialize node references
	parallax_background = get_node_or_null("ParallaxBackground")
	ground = get_node_or_null("Ground")
	obstacles = get_node_or_null("Obstacles")
	enemies = get_node_or_null("Enemies")
	props = get_node_or_null("Props")
	boss_spawn_point = get_node_or_null("BossSpawnPoint")
	
	setup_stage()

func setup_stage():
	# Set up cyberpunk-specific background
	setup_cyberpunk_background()
	
	# Set up cyberpunk-themed obstacles
	setup_cyberpunk_obstacles()
	
	# Set up cyberpunk props
	setup_cyberpunk_props()

func setup_cyberpunk_background():
	if not parallax_background:
		return
		
	# Create a cyberpunk city background
	var background = ColorRect.new()
	background.color = Color(0.05, 0.05, 0.1, 1.0)  # Dark blue-black
	background.size = Vector2(2000, 600)
	background.position = Vector2(-1000, -300)
	parallax_background.add_child(background)
	
	# Add skyscrapers
	for i in range(8):
		var building = ColorRect.new()
		building.color = Color(0.1, 0.1, 0.2, 1.0)  # Dark blue
		building.size = Vector2(80 + randf() * 40, 300 + randf() * 200)
		building.position = Vector2(i * 250 + randf() * 50, -building.size.y + 100)
		parallax_background.add_child(building)
		
		# Add neon lights to buildings
		for j in range(3):
			var neon = ColorRect.new()
			neon.color = Color(randf(), randf(), 1.0, 0.8)  # Random neon colors
			neon.size = Vector2(10, 20)
			neon.position = Vector2(
				building.position.x + randf() * building.size.x,
				building.position.y + j * 100 + randf() * 50
			)
			parallax_background.add_child(neon)

func setup_cyberpunk_obstacles():
	# Create cyberpunk-themed obstacles like energy barriers and drones
	# This will be populated during gameplay
	pass

func setup_cyberpunk_props():
	if not props:
		return
		
	# Add cyberpunk props like neon signs, holograms, etc.
	for i in range(6):
		var neon_sign = ColorRect.new()
		neon_sign.color = Color(1.0, 0.2, 0.8, 0.9)  # Pink neon
		neon_sign.size = Vector2(60, 15)
		neon_sign.position = Vector2(i * 350 + randf() * 100, 450 - neon_sign.size.y)
		props.add_child(neon_sign)
	
	# Add some holographic displays
	for i in range(4):
		var hologram = ColorRect.new()
		hologram.color = Color(0.2, 0.8, 1.0, 0.6)  # Cyan hologram
		hologram.size = Vector2(40, 60)
		hologram.position = Vector2(i * 500 + randf() * 200, 420 - hologram.size.y)
		props.add_child(hologram)

# Stage interface methods
func get_stage_name() -> String:
	return stage_name

func get_stage_description() -> String:
	return stage_description

func get_stage_number() -> int:
	return stage_number

func get_boss_scene() -> PackedScene:
	return boss_scene

func get_background_music() -> AudioStream:
	return background_music

func get_difficulty_multiplier() -> float:
	return difficulty_multiplier

func get_boss_spawn_position() -> Vector2:
	if boss_spawn_point:
		return boss_spawn_point.global_position
	return Vector2(5000, 0)  # Default spawn position

func spawn_boss() -> Node2D:
	if boss_spawned or not boss_scene:
		return null
	
	boss_spawned = true
	var boss = boss_scene.instantiate()
	boss.global_position = get_boss_spawn_position()
	add_child(boss)
	
	# Activate boss if it has the activate_boss method
	if boss.has_method("activate_boss"):
		boss.activate_boss()
		boss_active = true
	
	return boss

func complete_stage():
	stage_completed = true
	stage_completed_signal.emit()

func is_stage_completed() -> bool:
	return stage_completed

func cleanup_stage():
	# Clean up stage-specific elements
	if obstacles:
		for child in obstacles.get_children():
			if is_instance_valid(child):
				child.queue_free()
	
	if enemies:
		for child in enemies.get_children():
			if is_instance_valid(child):
				child.queue_free()
	
	if props:
		for child in props.get_children():
			if is_instance_valid(child):
				child.queue_free()

signal stage_completed_signal 