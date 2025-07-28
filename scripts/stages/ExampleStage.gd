extends Stage
class_name ExampleStage

# Override stage information for example theme
func _ready():
	stage_name = "Example Stage"
	stage_description = "An example stage showing how inheritance works"
	stage_number = 4
	difficulty_multiplier = 1.8
	
	# Call parent _ready() to initialize base stage
	super._ready()

func setup_stage():
	# Set up example-themed obstacles
	setup_example_obstacles()
	
	# Set up example props
	setup_example_props()

func setup_example_obstacles():
	# Create example-themed obstacles
	# This will be populated during gameplay
	pass

func setup_example_props():
	if not props:
		return
		
	# Add example props
	for i in range(4):
		var prop = ColorRect.new()
		prop.color = Color(0.8, 0.6, 0.2, 1.0)  # Gold
		prop.size = Vector2(50 + randf() * 30, 25 + randf() * 20)
		prop.position = Vector2(i * 400 + randf() * 200, 480 - prop.size.y)
		props.add_child(prop)

# Example of overriding a base method
func spawn_boss() -> Node2D:
	# Call parent method first
	var boss = super.spawn_boss()
	
	# Add stage-specific boss behavior
	if boss:
		print("Example stage boss spawned with special effects!")
		# Add special effects, different boss behavior, etc.
	
	return boss

# Example of adding stage-specific methods
func trigger_special_event():
	print("Example stage special event triggered!")
	# Stage-specific logic here 