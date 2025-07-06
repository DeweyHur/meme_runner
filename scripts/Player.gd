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
		
		# Store detailed debug info
		debug_info["floor_normal_x"] = floor_normal.x
		debug_info["floor_normal_y"] = floor_normal.y
		debug_info["floor_normal_length"] = floor_normal.length()
		
		# Check for inverted floor normal (Y > 0) - this indicates upside down collision
		if floor_normal.y > 0.0:  # Positive Y means upside down or invalid
			# Force player to fall and reset position
			velocity.y += gravity * 3.0
			debug_info["slope_type"] = "Inverted Floor (Y > 0)"
			debug_info["invalid_reason"] = "Floor normal Y is positive: %.3f" % floor_normal.y
			print("Inverted floor normal detected! Floor normal: ", floor_normal)
			return
		
		# Check for 180 degree angle (floor normal pointing straight down)
		if floor_normal.y < -0.99 and abs(floor_normal.x) < 0.1:
			# This is actually flat ground, not a 180° angle
			# The normal pointing down (-1, 0) is correct for flat ground
			debug_info["slope_type"] = "Flat Ground"
			debug_info["slope_angle"] = 0.0
			# Don't force fall - this is normal behavior
			return
		
		# Validate floor normal to prevent invalid angles
		if floor_normal.y > -0.1:  # If floor normal is too horizontal, something is wrong
			# Force player to fall
			velocity.y += gravity * 2.0
			debug_info["slope_type"] = "Invalid (Y > -0.1)"
			debug_info["invalid_reason"] = "Floor normal Y too high: %.3f" % floor_normal.y
			return
		
		# If we're on a slope (not flat ground)
		# Check if the normal has a significant X component (indicating slope)
		if abs(floor_normal.x) > 0.1:  # Significant horizontal component means slope
			# Calculate slope angle (use absolute value since normal is negative)
			var slope_angle = acos(abs(floor_normal.y))
			debug_info["slope_angle"] = slope_angle
			
			# If slope is walkable (less than 45 degrees)
			if slope_angle < 0.785398:  # 45 degrees in radians (PI/4)
				# Calculate the slope direction (positive = uphill, negative = downhill)
				var slope_direction = -floor_normal.x  # Negative because normal points away from surface
				
				# Adjust velocity to move along the slope
				# For uphill: reduce horizontal speed, add upward velocity
				# For downhill: maintain horizontal speed, add downward velocity
				if slope_direction > 0:  # Uphill
					velocity.y = -velocity.x * slope_direction * 0.5
				else:  # Downhill
					velocity.y = -velocity.x * slope_direction * 0.3
				
				debug_info["slope_type"] = "Walkable"
				debug_info["slope_direction"] = slope_direction
			else:
				# Too steep, slide down
				velocity.y += gravity * 0.5
				debug_info["slope_type"] = "Steep"
		else:
			debug_info["slope_type"] = "Flat"

func check_and_unstuck():
	# If player is on floor but has very low velocity, they might be stuck
	if is_on_floor() and abs(velocity.x) < 50.0 and abs(velocity.y) < 10.0:
		# Check if we're stuck for too long
		if not debug_info.has("stuck_timer"):
			debug_info["stuck_timer"] = 0.0
		
		debug_info["stuck_timer"] += get_process_delta_time()
		
		# If stuck for more than 1 second, force movement
		if debug_info["stuck_timer"] > 1.0:
			print("Player stuck detected! Forcing movement...")
			velocity.y = -100.0  # Force upward movement
			debug_info["stuck_timer"] = 0.0
	else:
		# Reset stuck timer if moving normally
		if debug_info.has("stuck_timer"):
			debug_info["stuck_timer"] = 0.0

func check_collision_setup():
	# Check if collision layers are set up correctly
	debug_info["collision_layer"] = collision_layer
	debug_info["collision_mask"] = collision_mask
	
	# Check if we're detecting ground properly
	var ground_detected = false
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.collision_layer == 1:  # Ground layer
			ground_detected = true
			debug_info["ground_collision"] = true
			debug_info["ground_collider_name"] = collider.name
			break
	
	if not ground_detected:
		debug_info["ground_collision"] = false
		debug_info["ground_collider_name"] = "None"

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
	
	# Check for stuck player and unstuck if necessary
	check_and_unstuck()
	
	# Check collision setup
	check_collision_setup()
	
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
