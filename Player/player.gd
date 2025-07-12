extends CharacterBody2D


const SPEED = 170.0
const JUMP_VELOCITY = -450.0

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var run_speed = SPEED  # Variable that can be modified externally
var is_jumping = false
var is_sliding = false
var is_crouching = false
var is_shooting = false
var is_hurt = false
var hurt_velocity = Vector2.ZERO
var hurt_timer = 0.0
var debug_info = {}  # Store debug information

# Slope handling variables
var max_walkable_slope_angle = 25.0  # Maximum slope angle in degrees that player can walk on
var slope_movement_enabled = true  # Whether to enable smooth slope movement
var current_slope_angle = 0.0  # Current slope angle in degrees
var slope_normal = Vector2.UP  # Normal vector of the current slope
var debug_slope_info = false  # Enable to show slope debug info

# Shooting variables
var shoot_timer = 0.0
var shoot_interval = 4.0  # Configurable shooting interval in seconds
var bullet_scene = preload("res://VFX/shot.tscn")

func _ready():
	# Add player to group so turrets can find it
	add_to_group("player")
	
	# Connect area collision signals
	var area2d = $Area2D
	if area2d:
		area2d.body_entered.connect(_on_area_body_entered)
		area2d.area_entered.connect(_on_area_area_entered)

func _physics_process(delta):
	# Handle hurt movement
	if is_hurt:
		hurt_timer += delta
		
		# Gradually slow down the hurt velocity
		var deceleration = 400.0  # pixels per second squared
		hurt_velocity.x = move_toward(hurt_velocity.x, 0, deceleration * delta)
		
		# Apply hurt velocity (backward movement)
		velocity = hurt_velocity
		move_and_slide()
		update_animations(0)  # No input during hurt
		return
	
	# Detect slope information when on floor
	if is_on_floor():
		detect_slope_info()
	else:
		# Reset slope info when not on floor
		current_slope_angle = 0.0
		slope_normal = Vector2.UP
	
	# Handle slope movement
	if is_on_floor() and slope_movement_enabled and abs(current_slope_angle) <= max_walkable_slope_angle:
		# On gradual slope - apply slope-based movement
		handle_slope_movement(delta)
	else:
		# Normal gravity when not on floor or on steep slopes
		if not is_on_floor():
			velocity.y += gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = true

	# Handle Back Jump (left arrow)
	if Input.is_action_just_pressed("ui_left") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		velocity.x = -run_speed * 0.5  # Move left at half speed while jumping
		is_jumping = true

	# Handle Crouch
	if Input.is_action_pressed("ui_down") and is_on_floor() and not is_jumping:
		is_crouching = true
		is_sliding = true  # Set sliding state for debug info
	else:
		is_crouching = false
		is_sliding = false

	# Handle Shooting
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot()
		shoot_timer = 0.0

	# Make the player run continuously forward (only if not back-jumping)
	if not is_jumping or velocity.x >= 0:
		velocity.x = run_speed

	move_and_slide()
	update_animations(1)  # Always pass 1 for forward movement
	
	# Check for collisions with obstacles
	check_collisions()
	
	# Update jumping state
	if is_on_floor() and is_jumping:
		is_jumping = false

func detect_slope_info():
	# Get slope information from the ground we're standing on
	var ground_info = get_ground_info_at_position()
	if ground_info.has("normal"):
		slope_normal = ground_info.normal
		# Calculate slope angle from normal
		var slope_radians = acos(slope_normal.y)
		current_slope_angle = rad_to_deg(slope_radians)
		
		# Determine if slope is downward (negative angle)
		if slope_normal.x > 0:  # Normal pointing right means downward slope
			current_slope_angle = -current_slope_angle
		
		# Debug output
		if debug_slope_info:
			print("Slope detected - Angle: %.1f°, Normal: %s" % [current_slope_angle, slope_normal])
	else:
		# Fallback: assume flat ground
		current_slope_angle = 0.0
		slope_normal = Vector2.UP

func get_ground_info_at_position() -> Dictionary:
	# Try to get ground information from procedural ground system
	var game_scene = get_parent()
	if game_scene and game_scene.has_method("get_ground_info_at_position"):
		return game_scene.get_ground_info_at_position(position.x)
	
	# Fallback: check collision with ground pieces
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider and collider.has_method("get_ground_info_at_x"):
			# Calculate x offset within the ground piece
			var local_pos = collider.to_local(position)
			return collider.get_ground_info_at_x(local_pos.x)
	
	# Default fallback
	return {"height": position.y, "normal": Vector2.UP}

func handle_slope_movement(delta):
	# Calculate slope-based movement
	var slope_radians = deg_to_rad(current_slope_angle)
	
	# For downward slopes, apply a gentle downward velocity
	if current_slope_angle < 0:
		# Calculate how much to move down based on slope angle
		var slope_velocity = run_speed * sin(abs(slope_radians))
		velocity.y = slope_velocity
		
		if debug_slope_info:
			print("Downhill movement - Slope: %.1f°, Velocity Y: %.1f" % [current_slope_angle, slope_velocity])
	else:
		# For upward slopes, maintain current y velocity (gravity will handle it)
		velocity.y = 0
	
	# Ensure we don't fall through the ground
	if velocity.y > 0:
		# Check if we're about to fall through
		var ground_info = get_ground_info_at_position()
		if ground_info.has("height"):
			var ground_height = ground_info.height
			if position.y + velocity.y * delta > ground_height:
				velocity.y = 0
				position.y = ground_height

# Getter methods for debug overlay
func get_current_slope_angle() -> float:
	return current_slope_angle

func get_slope_normal() -> Vector2:
	return slope_normal

func is_slope_movement_enabled() -> bool:
	return slope_movement_enabled

func update_animations(input_axis):
	
	if input_axis > 0:
		animated_sprite_2d.flip_h = false
	elif input_axis < 0:
		animated_sprite_2d.flip_h = true
		
	if is_hurt:
		animated_sprite_2d.play("hurt")
	elif is_on_floor():
		if is_crouching:
			animated_sprite_2d.play("crouch")
		elif is_shooting:
			animated_sprite_2d.play("shoot")
		elif input_axis != 0:
			animated_sprite_2d.play("run")
		else:
			animated_sprite_2d.play("idle")
	else:
		if velocity.y > 0:
			animated_sprite_2d.play("fall")
		else:
			animated_sprite_2d.play("jump")
	

func check_collisions():
	# Check for collision with obstacles
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Only trigger game over for obstacles, not ground
		if collider and collider.is_in_group("obstacles"):
			game_over()

func game_over():
	print("Game Over!")
	# Stop the player
	velocity = Vector2.ZERO
	# Signal the game scene
	var game_scene = get_parent()
	if game_scene.has_method("game_over"):
		game_scene.game_over()

func shoot():
	if not is_shooting:
		is_shooting = true
		
		# Spawn bullet
		var bullet = bullet_scene.instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = global_position + Vector2(50, -20)  # Spawn in front of player
		
		# Set bullet speed and direction for player shots
		bullet.speed = run_speed + 500
		bullet.direction = Vector2.RIGHT  # Player always shoots forward
		bullet.bullet_type = "player"  # Mark as player bullet
		print("🎯 Player spawned bullet - Type: %s, Speed: %.1f" % [bullet.bullet_type, bullet.speed])
		
		# Reset shooting state after animation
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 0.3  # Duration of shot animation
		timer.one_shot = true
		timer.timeout.connect(func(): is_shooting = false)
		timer.start()

func take_damage():
	print("Player took damage!")
	is_hurt = true
	hurt_timer = 0.0
	
	# Set hurt velocity for smooth backward movement
	hurt_velocity = Vector2(-300, 0)  # Move backward at 300 pixels per second
	
	# Signal the game scene that player took damage
	var game_scene = get_parent()
	if game_scene.has_method("player_took_damage"):
		game_scene.player_took_damage()
	
	# Play hurt animation and wait
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0  # Hurt duration
	timer.one_shot = true
	timer.timeout.connect(func(): 
		is_hurt = false
		hurt_velocity = Vector2.ZERO
		hurt_timer = 0.0
		print("Player recovered from damage!")
	)
	timer.start()

func _on_area_body_entered(body):
	# Handle collision with turrets
	print("Player area body collision - Target: %s, Groups: %s" % [body.name, str(body.get_groups())])
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		print("✅ VALID: Player hit by turret!")
		take_damage()
		body.take_damage()  # Destroy the turret
	else:
		print("ℹ️  Player hit by non-enemy body: %s" % body.name)

func _on_area_area_entered(area):
	# Handle collision with bullets
	print("Player area collision - Target: %s, Groups: %s" % [area.name, str(area.get_groups())])
	if area.has_method("_on_body_entered"):  # This is a bullet
		print("ℹ️  Player area collision with bullet-like object: %s" % area.name)
		# Note: Actual bullet damage is handled in the bullet's _on_body_entered method
		# This is just for tracking collision events
	else:
		print("ℹ️  Player area collision with non-bullet area: %s" % area.name)

	
