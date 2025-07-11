extends CharacterBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D

# Preview-specific variables
var is_preview_mode = true
var current_animation = "idle"

func _ready():
	# Disable physics processing for preview
	set_physics_process(false)
	set_process(false)
	
	# Start with idle animation
	play_animation("idle")

func play_animation(animation_name: String):
	if not animated_sprite_2d:
		return
	
	current_animation = animation_name
	
	# Map animation names to player states
	match animation_name:
		"idle":
			animated_sprite_2d.play("idle")
		"run":
			animated_sprite_2d.play("run")
		"jump":
			animated_sprite_2d.play("jump")
		"crouch":
			animated_sprite_2d.play("crouch")
		"shoot":
			animated_sprite_2d.play("shoot")
		"fall":
			animated_sprite_2d.play("fall")
		"hurt":
			animated_sprite_2d.play("hurt")
		_:
			animated_sprite_2d.play("idle")

# Override the update_animations method to work in preview mode
func update_animations(input_axis):
	if not is_preview_mode:
		# In non-preview mode, this would call the parent player logic
		# For now, just play the current animation
		play_animation(current_animation)
		return
	
	# In preview mode, just play the current animation
	play_animation(current_animation)

# Method to set animation state for preview
func set_animation_state(animation: String):
	play_animation(animation) 