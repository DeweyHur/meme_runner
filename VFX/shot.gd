extends Area2D

var speed = 300.0  # Default speed, will be overridden by player
var direction = Vector2.RIGHT  # Direction vector for movement
var bullet_type = "player"  # "player" or "turret"
var has_hit = false

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Add to bullets group for tracking
	add_to_group("bullets")
	
	# Connect collision signal
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	# Start with fly animation
	animated_sprite.play("fly")
	
	# Validate bullet type
	if bullet_type != "player" and bullet_type != "turret":
		print("⚠️  WARNING: Invalid bullet type: %s" % bullet_type)
		bullet_type = "player"  # Default to player bullet
		print("   Set to default type: %s" % bullet_type)
	
	# Debug collision setup
	print("🔫 Bullet created - Type: %s, Layer: 2, Mask: 3" % bullet_type)

func _physics_process(delta):
	if not has_hit:
		# Move in the specified direction
		position += direction * speed * delta

func _on_body_entered(body):
	if not has_hit:
		has_hit = true
		
		# Stop movement
		set_physics_process(false)
		
		# Play hit animation
		animated_sprite.play("hit")
		
		# Debug collision info
		print("Bullet collision - Type: %s, Target: %s, Target Group: %s" % [bullet_type, body.name, "player" if body.is_in_group("player") else "other"])
		
		# Check if hit player (only for turret bullets)
		if bullet_type == "turret" and body.is_in_group("player") and body.has_method("take_damage"):
			print("✅ VALID: Turret bullet hit player!")
			body.take_damage()
		elif bullet_type == "player" and body.is_in_group("player"):
			print("❌ INVALID: Player bullet hit player! This should not happen!")
			print("   Bullet type: %s" % bullet_type)
			print("   Target: %s" % body.name)
			print("   Target groups: %s" % str(body.get_groups()))
		else:
			print("ℹ️  Bullet hit non-player target: %s" % body.name)
		
		# Wait for hit animation to complete then remove
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 0.8
		timer.one_shot = true
		timer.timeout.connect(queue_free)
		timer.start()

func get_debug_info() -> String:
	return "Bullet[%s] - Type: %s, Speed: %.1f, Direction: %s, HasHit: %s" % [
		name, bullet_type, speed, direction, str(has_hit)
	]

func _on_area_entered(area):
	if not has_hit and area.is_in_group("enemies"):
		print("Bullet area collision - Type: %s, Target: %s" % [bullet_type, area.name])
		has_hit = true
		
		# Stop movement
		set_physics_process(false)
		
		# Play hit animation
		animated_sprite.play("hit")
		
		# Damage the enemy (only for player bullets)
		if bullet_type == "player" and area.has_method("take_damage"):
			print("✅ VALID: Player bullet hit enemy!")
			area.take_damage()
		elif bullet_type == "turret" and area.is_in_group("enemies"):
			print("❌ INVALID: Turret bullet hit enemy! This should not happen!")
			print("   Bullet type: %s" % bullet_type)
			print("   Target: %s" % area.name)
			print("   Target groups: %s" % str(area.get_groups()))
		else:
			print("ℹ️  Bullet hit non-enemy area: %s" % area.name)
		
		# Wait for hit animation to complete then remove
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 0.8
		timer.one_shot = true
		timer.timeout.connect(queue_free)
		timer.start() 