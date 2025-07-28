extends Stage
class_name CyberpunkStage

# Override stage information for cyberpunk theme
func _ready():
	stage_name = "Cyberpunk Stage"
	stage_description = "A neon-lit cityscape with towering skyscrapers and flying cars"
	stage_number = 2
	difficulty_multiplier = 1.2
	
	# Call parent _ready() to initialize base stage
	super._ready()

# Override boss spawn position to place boss above ground
func get_boss_spawn_position() -> Vector2:
	var base_spawn_pos = super.get_boss_spawn_position()
	# Place boss 200 pixels above ground level (around Y=300)
	return Vector2(base_spawn_pos.x, 300)

func setup_stage():
	# Set up cyberpunk-themed obstacles
	setup_cyberpunk_obstacles()
	
	# Set up cyberpunk props
	setup_cyberpunk_props()

func setup_cyberpunk_obstacles():
	# Create cyberpunk-themed obstacles like energy barriers and drones
	# This will be populated during gameplay
	pass

func setup_cyberpunk_props():
	if not props:
		return
		
	# Add cyberpunk props like neon signs, holograms, etc.
	for i in range(6):
		var neon_sign = ColorRect.new()
		neon_sign.color = Color(1.0, 0.2, 0.8, 0.9)  # Pink neon
		neon_sign.size = Vector2(60, 15)
		neon_sign.position = Vector2(i * 350 + randf() * 100, 450 - neon_sign.size.y)
		props.add_child(neon_sign)
	
	# Add some holographic displays
	for i in range(4):
		var hologram = ColorRect.new()
		hologram.color = Color(0.2, 0.8, 1.0, 0.6)  # Cyan hologram
		hologram.size = Vector2(40, 60)
		hologram.position = Vector2(i * 500 + randf() * 200, 420 - hologram.size.y)
		props.add_child(hologram) 