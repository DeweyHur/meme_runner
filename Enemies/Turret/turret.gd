extends Area2D

var player = null
var shoot_timer = 0.0
var shoot_interval = 2.0  # Time between shots
var bullet_scene = preload("res://VFX/shot.tscn")
var explosion_scene = preload("res://VFX/explosion.tscn")

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Add to enemies group for bullet collision detection
	add_to_group("enemies")
	
	# Connect collision signal for player collision
	body_entered.connect(_on_body_entered)
	
	# Find the player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		# Try to find player by name
		player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta):
	if player:
		shoot_timer += delta
		if shoot_timer >= shoot_interval:
			shoot_at_player()
			shoot_timer = 0.0

func shoot_at_player():
	if player and is_instance_valid(player):
		# Calculate direction to player
		var direction = (player.global_position - global_position).normalized()
		
		# Spawn bullet
		var bullet = bullet_scene.instantiate()
		get_parent().add_child(bullet)
		
		# Spawn bullet in front of turret (considering turret rotation)
		var spawn_offset = Vector2(0, -10).rotated(rotation)
		bullet.global_position = global_position + spawn_offset
		
		# Set bullet speed and direction
		bullet.speed = 200.0
		bullet.direction = direction
		bullet.bullet_type = "turret"  # Mark as turret bullet
		print("🎯 Turret spawned bullet - Type: %s, Speed: %.1f, Direction: %s, Turret Rotation: %.2f°" % [
			bullet.bullet_type, bullet.speed, direction, rad_to_deg(rotation)
		])
		
		# Rotate bullet sprite to face direction
		if bullet.has_node("AnimatedSprite2D"):
			var angle = direction.angle()
			bullet.get_node("AnimatedSprite2D").rotation = angle

func take_damage():
	print("Turret destroyed!")
	# Play explosion effect
	var explosion = explosion_scene.instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	
	# Remove the turret
	queue_free()

func _on_body_entered(body):
	# Check if the body is the player
	if body.is_in_group("player") and body.has_method("take_damage"):
		print("Turret hit player!")
		body.take_damage()
		
		# Remove the turret after hitting player
		queue_free() 