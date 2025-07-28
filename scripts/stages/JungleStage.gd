extends Stage
class_name JungleStage

static func test_function():
	print("JungleStage script is loaded!")

# Override stage information for jungle theme
func _ready():
	stage_name = "Jungle Stage"
	stage_description = "A dense jungle filled with ancient ruins and dangerous wildlife"
	stage_number = 1
	difficulty_multiplier = 1.0
	
	# Call parent _ready() to initialize base stage
	super._ready()

func setup_stage():
	# Set up jungle-themed obstacles
	setup_jungle_obstacles()
	
	# Set up jungle props
	setup_jungle_props()

func setup_jungle_obstacles():
	# Create jungle-themed obstacles like fallen logs and vines
	# This will be populated during gameplay
	pass

func setup_jungle_props():
	if not props:
		return
		
	# Add jungle props like rocks, bushes, etc.
	for i in range(5):
		var rock = ColorRect.new()
		rock.color = Color(0.4, 0.4, 0.4, 1.0)  # Gray
		rock.size = Vector2(30 + randf() * 20, 20 + randf() * 15)
		rock.position = Vector2(i * 400 + randf() * 200, 480 - rock.size.y)
		props.add_child(rock)
	
	# Add some bushes
	for i in range(8):
		var bush = ColorRect.new()
		bush.color = Color(0.2, 0.5, 0.2, 1.0)  # Medium green
		bush.size = Vector2(40 + randf() * 20, 30 + randf() * 20)
		bush.position = Vector2(i * 300 + randf() * 150, 470 - bush.size.y)
		props.add_child(bush) 
