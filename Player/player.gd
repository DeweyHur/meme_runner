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
var debug_info = {}  # Store debug information

# Shooting variables
var shoot_timer = 0.0
var shoot_interval = 1.0  # Configurable shooting interval in seconds
var bullet_scene = preload("res://VFX/shot.tscn")


func _physics_process(delta):
	# Add the gravity.
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

func update_animations(input_axis):
	
	if input_axis > 0:
		animated_sprite_2d.flip_h = false
	elif input_axis < 0:
		animated_sprite_2d.flip_h = true
		
	if is_on_floor():
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
		
		# Set bullet speed relative to player run speed
		bullet.speed = run_speed
		
		# Reset shooting state after animation
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 0.3  # Duration of shot animation
		timer.one_shot = true
		timer.timeout.connect(func(): is_shooting = false)
		timer.start()

	
