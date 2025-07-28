extends Node2D

# Stage information
@export var stage_name: String = "Jungle Stage"
@export var stage_description: String = "A dense jungle filled with ancient ruins and dangerous wildlife"
@export var stage_number: int = 1
@export var boss_scene: PackedScene
@export var background_music: AudioStream
@export var difficulty_multiplier: float = 1.0

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
	# Set up jungle-specific background
	setup_jungle_background()
	
	# Set up jungle-themed obstacles
	setup_jungle_obstacles()
	
	# Set up jungle props
	setup_jungle_props()

func setup_jungle_background():
	if not parallax_background:
		return
		
	# Create a simple jungle background using colored rectangles
	var background = ColorRect.new()
	background.color = Color(0.1, 0.3, 0.1, 1.0)  # Dark green
	background.size = Vector2(2000, 600)
	background.position = Vector2(-1000, -300)
	parallax_background.add_child(background)
	
	# Add some tree silhouettes
	for i in range(10):
		var tree = ColorRect.new()
		tree.color = Color(0.05, 0.2, 0.05, 1.0)  # Darker green
		tree.size = Vector2(50, 200 + randf() * 100)
		tree.position = Vector2(i * 200 + randf() * 100, -tree.size.y + 100)
		parallax_background.add_child(tree)

func setup_jungle_obstacles():
	# Create jungle-themed obstacles like fallen logs and vines
	# This will be populated during gameplay
	pass

func setup_jungle_props():
	if not props:
		return
		
	# Add jungle props like rocks, bushes, etc.
	for i in range(5):
		var rock = ColorRect.new()
		rock.color = Color(0.4, 0.4, 0.4, 1.0)  # Gray
		rock.size = Vector2(30 + randf() * 20, 20 + randf() * 15)
		rock.position = Vector2(i * 400 + randf() * 200, 480 - rock.size.y)
		props.add_child(rock)
	
	# Add some bushes
	for i in range(8):
		var bush = ColorRect.new()
		bush.color = Color(0.2, 0.5, 0.2, 1.0)  # Medium green
		bush.size = Vector2(40 + randf() * 20, 30 + randf() * 20)
		bush.position = Vector2(i * 300 + randf() * 150, 470 - bush.size.y)
		props.add_child(bush)

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
