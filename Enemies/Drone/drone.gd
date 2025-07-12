extends Area2D

var direction = -1
var speed = 80

func _ready():
	# Add to enemies group for bullet collision detection
	add_to_group("enemies")
	
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	print("Drone created - Layer: 2, Mask: 1, Group: enemies")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position.x += speed * delta * direction
	
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
