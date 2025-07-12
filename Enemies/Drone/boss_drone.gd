extends Area2D

var direction = -1
var speed = 800  # Much higher speed to keep up with fast-moving player
var max_hp = 100
var current_hp = 100
var is_boss = true
var is_active = false

# Boss battle variables
var shoot_timer = 0.0
var shoot_interval = 2.0  # Shoot every 2 seconds
var bullet_scene = preload("res://VFX/shot.tscn")
var target_player: Node2D = null
var boss_distance = 400.0  # Distance to maintain from player
var movement_pattern = "follow"  # "follow", "circle", "strafe"

# Independent Y movement variables
var y_movement_timer = 0.0
var y_movement_interval = 2.0  # Change Y direction every 2 seconds
var y_direction = 1  # 1 for up, -1 for down
var y_speed = 50.0  # Speed of Y movement
var y_bounds_min = 200.0  # Minimum Y position
var y_bounds_max = 400.0  # Maximum Y position

# Visual feedback
var original_color: Color
var damage_flash_timer = 0.0
var damage_flash_duration = 0.2

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

func _ready():
	# Add to enemies group
	add_to_group("enemies")
	add_to_group("boss")
	
	# Debug collision setup
	print("Boss collision setup - Layer: %d, Mask: %d, Groups: %s" % [collision_layer, collision_mask, str(get_groups())])
	
	# Store original color for damage flashing
	if sprite:
		original_color = sprite.modulate
	
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Find player
	find_player()

func _process(delta):
	if not is_active or not target_player:
		return
	
	# Handle damage flash
	if damage_flash_timer > 0:
		damage_flash_timer -= delta
		if damage_flash_timer <= 0:
			if sprite:
				sprite.modulate = original_color
	
	# Boss movement logic
	handle_boss_movement(delta)
	handle_boss_y_movement(delta)
	
	# Boss shooting logic
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_at_player()
		shoot_timer = 0.0

func find_player():
	# Try to find player in various ways
	target_player = get_tree().get_first_node_in_group("player")
	if not target_player:
		print("Boss: Player not found in 'player' group, searching all nodes...")
		# Try finding by script
		var all_nodes = get_tree().get_nodes_in_group("")
		for node in all_nodes:
			if node.has_method("get_velocity") and node is CharacterBody2D:
				target_player = node
				print("Boss: Found player by method check: ", node.name)
				break
	
	if target_player:
		print("Boss drone found player: ", target_player.name)
		print("Boss: Player position: ", target_player.global_position)
	else:
		print("Boss drone could not find player!")
		print("Boss: Available groups: ", get_tree().get_nodes_in_group("player"))

func handle_boss_movement(delta):
	if not target_player:
		print("Boss movement: No target player!")
		return
	
	var player_pos = target_player.global_position
	var boss_pos = global_position
	
	# Maintain consistent x distance from player
	var target_x = player_pos.x + boss_distance
	var current_x_diff = abs(boss_pos.x - target_x)
	
	# Debug movement info
	if Engine.get_process_frames() % 120 == 0:  # Print every 2 seconds
		var actual_x_distance = boss_pos.x - player_pos.x
		print("Boss movement debug:")
		print("  Player pos: %.1f" % player_pos.x)
		print("  Boss pos: %.1f" % boss_pos.x)
		print("  Target x: %.1f" % target_x)
		print("  Current diff: %.1f" % current_x_diff)
		print("  Actual distance: %.1f (target: %.1f)" % [actual_x_distance, boss_distance])
	
	# Move towards target x position if not close enough
	if current_x_diff > 10:  # Small tolerance
		var x_direction = 1 if target_x > boss_pos.x else -1
		
		# Use higher speed when far behind to catch up quickly
		var effective_speed = speed
		if current_x_diff > 100:  # If more than 100 units behind, boost speed
			effective_speed = speed * 2.0
		
		var move_amount = x_direction * effective_speed * delta
		global_position.x += move_amount
		
		# Clamp to ensure we don't overshoot
		if x_direction > 0 and global_position.x > target_x:
			global_position.x = target_x
		elif x_direction < 0 and global_position.x < target_x:
			global_position.x = target_x
		
		if Engine.get_process_frames() % 120 == 0:
			print("  Moving boss by %.1f in direction %d (speed: %.1f)" % [move_amount, x_direction, effective_speed])
	
	# Y movement is now handled separately in handle_boss_y_movement()

func shoot_at_player():
	if not target_player or not bullet_scene:
		return
	
	# Calculate direction to player
	var direction_to_player = (target_player.global_position - global_position).normalized()
	
	# Spawn bullet
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position + direction_to_player * 30  # Spawn slightly in front
	
	# Set bullet properties
	bullet.speed = 200.0
	bullet.direction = direction_to_player
	bullet.bullet_type = "boss"  # Boss bullets for proper collision detection
	
	print("Boss drone shot at player!")

func take_damage(amount: int = 25):
	if not is_active:
		return
	
	current_hp -= amount
	print("Boss drone took damage! HP: %d/%d" % [current_hp, max_hp])
	
	# Visual feedback
	damage_flash_timer = damage_flash_duration
	if sprite:
		sprite.modulate = Color.RED
	
	# Check if boss is defeated
	if current_hp <= 0:
		defeat_boss()
	else:
		# Increase difficulty as HP decreases
		var hp_percentage = float(current_hp) / float(max_hp)
		shoot_interval = 2.0 + (1.0 - hp_percentage) * 1.0  # Faster shooting at low HP

func defeat_boss():
	print("Boss drone defeated!")
	is_active = false
	
	# Play defeat animation
	if animation_player:
		animation_player.play("RESET")
	
	# Signal victory to game
	var game_scene = get_parent()
	if game_scene and game_scene.has_method("boss_defeated"):
		game_scene.boss_defeated()
	
	# Remove boss after a delay
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	timer.start()

func handle_boss_y_movement(delta):
	# Update Y movement timer
	y_movement_timer += delta
	
	# Change Y direction randomly
	if y_movement_timer >= y_movement_interval:
		y_movement_timer = 0.0
		y_direction = randi_range(-1, 1)  # Random direction: -1, 0, or 1
		y_movement_interval = randf_range(1.5, 3.0)  # Random interval between 1.5-3 seconds
	
	# Apply Y movement
	if y_direction != 0:
		global_position.y += y_direction * y_speed * delta
	
	# Clamp Y position to bounds
	global_position.y = clamp(global_position.y, y_bounds_min, y_bounds_max)
	
	# Debug Y movement
	if Engine.get_process_frames() % 120 == 0:
		print("Boss Y movement - Pos: %.1f, Direction: %d, Bounds: [%.1f, %.1f]" % [
			global_position.y, y_direction, y_bounds_min, y_bounds_max
		])

func activate_boss():
	print("Boss drone activated!")
	print("Boss: is_active set to true")
	print("Boss: Current position: ", global_position)
	is_active = true
	current_hp = max_hp
	
	# Re-find player after activation
	find_player()
	
	# Start boss music or effects here if needed

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()

func _on_area_entered(area):
	# Handle bullet collisions
	print("Boss area collision - Target: %s, Groups: %s" % [area.name, str(area.get_groups())])
	
	if area.is_in_group("bullets"):
		print("Boss hit by bullet - Type: %s" % area.bullet_type)
		if area.bullet_type == "player":
			print("✅ Boss taking damage from player bullet!")
			take_damage(25)  # Player bullets do 25 damage
			area.queue_free()  # Destroy the bullet
		else:
			print("ℹ️  Boss hit by non-player bullet: %s" % area.bullet_type)
	else:
		print("ℹ️  Boss area collision with non-bullet: %s" % area.name)

func get_hp_percentage() -> float:
	return float(current_hp) / float(max_hp) 