extends Stage
class_name VolcanoStage

# Override stage information for volcano theme
func _ready():
	stage_name = "Volcano Stage"
	stage_description = "A treacherous volcanic landscape with flowing lava and ash clouds"
	stage_number = 3
	difficulty_multiplier = 1.5
	
	# Call parent _ready() to initialize base stage
	super._ready()

func setup_stage():
	# Set up volcano-themed obstacles
	setup_volcano_obstacles()
	
	# Set up volcano props
	setup_volcano_props()

func setup_volcano_obstacles():
	# Create volcano-themed obstacles like lava pools and falling rocks
	# This will be populated during gameplay
	pass

func setup_volcano_props():
	if not props:
		return
		
	# Add volcano props like rocks, lava pools, etc.
	for i in range(7):
		var rock = ColorRect.new()
		rock.color = Color(0.5, 0.3, 0.2, 1.0)  # Brown rock
		rock.size = Vector2(40 + randf() * 30, 25 + randf() * 20)
		rock.position = Vector2(i * 300 + randf() * 150, 475 - rock.size.y)
		props.add_child(rock)
	
	# Add some lava pools
	for i in range(3):
		var lava_pool = ColorRect.new()
		lava_pool.color = Color(1.0, 0.4, 0.0, 0.8)  # Orange lava
		lava_pool.size = Vector2(80 + randf() * 40, 20)
		lava_pool.position = Vector2(i * 600 + randf() * 200, 480 - lava_pool.size.y)
		props.add_child(lava_pool) 