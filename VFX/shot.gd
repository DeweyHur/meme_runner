extends Area2D

var speed = 300.0  # Default speed, will be overridden by player
var has_hit = false

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Connect collision signal
	body_entered.connect(_on_body_entered)
	# Start with fly animation
	animated_sprite.play("fly")

func _physics_process(delta):
	if not has_hit:
		# Move forward at the speed set by the player
		position.x += speed * delta

func _on_body_entered(body):
	if not has_hit:
		has_hit = true
		
		# Stop movement
		set_physics_process(false)
		
		# Play hit animation
		animated_sprite.play("hit")
		
		# Wait for hit animation to complete then remove
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 0.8
		timer.one_shot = true
		timer.timeout.connect(queue_free)
		timer.start() 