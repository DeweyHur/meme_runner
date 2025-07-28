extends Node2D
class_name Stage

# Stage information
@export var stage_name: String = "Unknown Stage"
@export var stage_description: String = "A mysterious stage"
@export var stage_number: int = 1
@export var boss_scene: PackedScene
@export var background_music: AudioStream
@export var difficulty_multiplier: float = 1.0

# Stage-specific variables
var boss_spawned: bool = false
var boss_active: bool = false
var stage_completed: bool = false

# Stage elements
@onready var parallax_background: Node2D = $ParallaxBackground
@onready var ground: Node2D = $Ground
@onready var obstacles: Node2D = $Obstacles
@onready var enemies: Node2D = $Enemies
@onready var props: Node2D = $Props
@onready var boss_spawn_point: Marker2D = $BossSpawnPoint

func _ready():
	setup_stage()

func setup_stage():
	# Override this in derived stages to set up stage-specific content
	pass

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