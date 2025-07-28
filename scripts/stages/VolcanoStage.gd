extends Node2D

# Stage information
@export var stage_name: String = "Volcano Stage"
@export var stage_description: String = "A treacherous volcanic landscape with flowing lava and ash clouds"
@export var stage_number: int = 3
@export var boss_scene: PackedScene
@export var background_music: AudioStream
@export var difficulty_multiplier: float = 1.5

# Stage-specific variables
var boss_spawned: bool = false
var boss_active: bool = false
var stage_completed: bool = false

# Stage elements
var parallax_background: ParallaxBackground
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
	# Set up volcano-themed obstacles
	setup_volcano_obstacles()
	
	# Set up volcano props
	setup_volcano_props()



func setup_volcano_obstacles():
	# Create volcano-themed obstacles like lava pools and falling rocks
	# This will be populated during gameplay
	pass

func setup_volcano_props():
	if not props:
		return
		
	# Add volcano props like rocks, lava pools, etc.
	for i in range(7):
		var rock = ColorRect.new()
		rock.color = Color(0.5, 0.3, 0.2, 1.0)  # Brown rock
		rock.size = Vector2(40 + randf() * 30, 25 + randf() * 20)
		rock.position = Vector2(i * 300 + randf() * 150, 475 - rock.size.y)
		props.add_child(rock)
	
	# Add some lava pools
	for i in range(3):
		var lava_pool = ColorRect.new()
		lava_pool.color = Color(1.0, 0.4, 0.0, 0.8)  # Orange lava
		lava_pool.size = Vector2(80 + randf() * 40, 20)
		lava_pool.position = Vector2(i * 600 + randf() * 200, 480 - lava_pool.size.y)
		props.add_child(lava_pool)

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