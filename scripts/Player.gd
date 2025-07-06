extends CharacterBody2D

@export var run_speed = 300.0
@export var jump_velocity = -400.0
@export var slide_speed = 200.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_sliding = false
var is_jumping = false
var can_jump = true
var can_slide = true
var debug_info = {}  # Store debug information

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	# Set initial position
	position = Vector2(100, 300)
	
	# Set collision layers for proper ground detection
	collision_layer = 2  # Player layer
	collision_mask = 1   # Detect ground layer
	
	# Make sure we're on the ground
	if is_on_floor():
		position.y = 300

func handle_slope_movement():
	# If on floor, check if we're on a slope and adjust movement
	if is_on_floor():
		# Get the floor normal to determine slope direction
		var floor_normal = get_floor_normal()
		
		# Store debug info
		debug_info["floor_normal"] = floor_normal
		debug_info["slope_angle"] = 0.0
		debug_info["slope_type"] = "Flat"
		
		# If we're on a slope (not flat ground)
		if floor_normal.y < 0.9:  # Less than 0.9 means we're on a slope
			# Calculate slope angle
			var slope_angle = acos(floor_normal.y)
			debug_info["slope_angle"] = slope_angle
			
			# If slope is walkable (less than 45 degrees)
			if slope_angle < 0.785398:  # 45 degrees in radians (PI/4)
				# Adjust velocity to move along the slope
				var slope_velocity = velocity.x / cos(slope_angle)
				velocity.y = -slope_velocity * sin(slope_angle)
				debug_info["slope_type"] = "Walkable"
				debug_info["slope_velocity"] = slope_velocity
			else:
				# Too steep, slide down
				velocity.y += gravity * 0.5
				debug_info["slope_type"] = "Steep"
		else:
			debug_info["slope_type"] = "Flat"

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
	
	# Handle slope movement
	handle_slope_movement()
	
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
		
		# Only trigger game over for obstacles, not ground
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
