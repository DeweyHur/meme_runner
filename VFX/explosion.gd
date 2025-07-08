extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Play the explosion animation
	animated_sprite.play("default")
	
	# Connect animation finished signal
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished():
	# Remove the explosion when animation is complete
	queue_free() 