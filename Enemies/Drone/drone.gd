extends RigidBody2D

var direction = -1
var speed = 80
var target_distance = 400.0  # X distance to maintain from player
var player = null
var max_speed = 150.0  # Maximum physics velocity
var pulse_timer = 0.0  # Timer for pulsing effect

func _ready():
	# Add to enemies group for bullet collision detection
	add_to_group("enemies")
	
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	
	# Connect area collision signals for bullet detection
	var area2d = $Area2D
	if area2d:
		area2d.area_entered.connect(_on_area_entered)
	
	# Find the player
	player = get_tree().get_first_node_in_group("player")
	
	# Set up physics properties
	gravity_scale = 0.0  # No gravity for flying drone
	linear_damp = 2.0  # Add some damping for smoother movement
	mass = 1.0  # Light mass for responsive movement
	freeze = false  # Allow physics to affect the body
	
	print("Drone created with physics - Layer: 2, Mask: 1, Group: enemies")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return
	
	# Calculate desired position to maintain X distance from player
	var player_pos = player.global_position
	var drone_pos = global_position
	
	# Calculate target position (maintain X distance from player, stay at current Y)
	var target_x = player_pos.x + target_distance
	var target_position = Vector2(target_x, drone_pos.y)
	
	# Keep drone at a good height above ground (around Y=300)
	var ground_height = 500.0  # Approximate ground level
	var target_y = ground_height - 200.0  # 200 pixels above ground
	target_position.y = target_y
	
	# Calculate desired velocity to reach target position
	var desired_velocity = (target_position - drone_pos) * speed
	
	# Apply physics-based movement with smooth acceleration
	var current_velocity = linear_velocity
	var velocity_change = desired_velocity - current_velocity
	
	# Apply force to move towards target position (smooth acceleration)
	apply_central_force(velocity_change * 3.0)  # Increased force for more responsive movement
	
	# Limit maximum velocity
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed
	
	# Add subtle random movement for more dynamic behavior
	var random_force = Vector2(randf_range(-3, 3), randf_range(-3, 3))
	apply_central_force(random_force)
	
	# Boss behavior: occasionally make small movements to dodge
	if randf() < 0.02:  # 2% chance per frame
		var dodge_force = Vector2(randf_range(-20, 20), randf_range(-10, 10))
		apply_central_force(dodge_force)
	
	# Boss behavior: maintain minimum distance from player
	var distance_to_player = drone_pos.distance_to(player_pos)
	if distance_to_player < 300:  # If too close, move away
		var away_force = (drone_pos - player_pos).normalized() * 50.0
		apply_central_force(away_force)
	
	# Rotate drone to face movement direction for visual effect
	if linear_velocity.length() > 10:
		var target_rotation = linear_velocity.angle()
		rotation = lerp_angle(rotation, target_rotation, 0.1)
	
	# Boss visual effect: subtle pulsing scale
	pulse_timer += delta
	var pulse_scale = 1.0 + sin(pulse_timer * 2.0) * 0.05
	scale = Vector2(pulse_scale, pulse_scale)
	
	# Debug info (uncomment for testing)
	#if Engine.is_editor_hint() == false:
	#	print("Drone Physics - Pos: ", global_position, " Vel: ", linear_velocity, " Distance: ", distance_to_player)
	
func turn_around():
	direction *= -1

func take_damage():
	print("Drone destroyed!")
	# Play explosion effect if available
	var explosion_scene = preload("res://VFX/explosion.tscn")
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_parent().add_child(explosion)
		explosion.global_position = global_position
	
	# Remove the drone
	queue_free()

func _on_body_entered(body):
	# Check if the body is the player
	if body.is_in_group("player") and body.has_method("take_damage"):
		print("Drone hit player!")
		body.take_damage()
		
		# Remove the drone after hitting player
		queue_free()

func _on_area_entered(area):
	# Handle bullet collisions
	print("Drone area collision - Target: %s, Groups: %s" % [area.name, str(area.get_groups())])
	
	if area.is_in_group("bullets"):
		print("Drone hit by bullet - Type: %s" % area.bullet_type)
		if area.bullet_type == "player":
			print("✅ Drone taking damage from player bullet!")
			take_damage()
			area.queue_free()  # Destroy the bullet
		else:
			print("ℹ️  Drone hit by non-player bullet: %s" % area.bullet_type)
	else:
		print("ℹ️  Drone area collision with non-bullet: %s" % area.name)
