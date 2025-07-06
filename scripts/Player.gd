extends CharacterBody2D

@export var run_speed = 300.0
@export var jump_velocity = -400.0
@export var slide_speed = 200.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_sliding = false
var is_jumping = false
var can_jump = true
var can_slide = true

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	# Set initial position
	position = Vector2(100, 300)

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		is_jumping = true
	else:
		is_jumping = false
		can_jump = true
		can_slide = true

	# Handle running
	velocity.x = run_speed
	
	# Handle jumping
	if Input.is_action_just_pressed("jump") and can_jump and is_on_floor():
		velocity.y = jump_velocity
		can_jump = false
		is_jumping = true
	
	# Handle sliding
	if Input.is_action_pressed("slide") and can_slide and is_on_floor() and not is_jumping:
		if not is_sliding:
			start_slide()
	else:
		if is_sliding:
			stop_slide()
	
	# Handle arrow key controls
	if Input.is_action_just_pressed("ui_up") and can_jump and is_on_floor():
		velocity.y = jump_velocity
		can_jump = false
		is_jumping = true
	
	if Input.is_action_pressed("ui_down") and can_slide and is_on_floor() and not is_jumping:
		if not is_sliding:
			start_slide()
	
	# Update animation
	update_animation()
	
	move_and_slide()
	
	# Check for collision with obstacles
	check_collisions()

func start_slide():
	is_sliding = true
	can_slide = false
	# Make collision shape smaller for sliding
	collision_shape.shape.size.y = 32
	collision_shape.position.y = 16
	# Slow down during slide
	velocity.x = slide_speed

func stop_slide():
	is_sliding = false
	# Restore normal collision shape
	collision_shape.shape.size.y = 64
	collision_shape.position.y = 0
	# Restore normal speed
	velocity.x = run_speed

func update_animation():
	if is_sliding:
		animated_sprite.modulate = Color(1, 0.5, 0.5, 1)  # Red tint for sliding
	else:
		animated_sprite.modulate = Color(0.2, 0.6, 1, 1)  # Normal blue color

func check_collisions():
	# Check for collision with obstacles
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.is_in_group("obstacles"):
			game_over()

func game_over():
	print("Game Over!")
	# Stop the player
	velocity = Vector2.ZERO
	# Signal the game scene
	var game_scene = get_parent()
	if game_scene.has_method("game_over"):
		game_scene.game_over() 