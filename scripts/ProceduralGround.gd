extends Node2D

@export var segment_width = 200.0
@export var ground_height = 50.0
@export var max_height_variation = 100.0
@export var min_segment_length = 3
@export var max_segment_length = 8
@export var smoothness = 0.3  # How smooth the transitions are (0-1)
@export var terrain_complexity = 0.7  # How complex the terrain should be

var player: Node2D
var last_segment_end = 0.0
var current_height = 500.0
var target_height = 500.0
var segments: Array[Node2D] = []
var max_segments = 10  # Keep only this many segments in memory
var terrain_seed = 0

func _ready():
	player = get_parent().get_node("Player")
	if not player:
		push_error("Player not found!")
		return
	
	# Set random seed for consistent terrain generation
	terrain_seed = randi()
	seed(terrain_seed)
	
	# Generate initial ground
	generate_initial_ground()

func _process(delta):
	if not player:
		return
	
	# Check if we need to generate more ground
	if player.position.x + 1000 > last_segment_end:
		generate_next_segment()
	
	# Clean up old segments
	cleanup_old_segments()

func generate_initial_ground():
	# Generate a few segments to start
	for i in range(5):
		generate_next_segment()

func generate_next_segment():
	# Determine segment length
	var segment_length = randi_range(min_segment_length, max_segment_length)
	
	# Generate terrain type and height
	var terrain_type = choose_terrain_type()
	var height_change = calculate_height_change(terrain_type)
	target_height = float(current_height) + float(height_change)
	
	# Clamp height to reasonable bounds
	target_height = clamp(target_height, 400.0, 600.0)
	
	# Create the segment
	var segment = create_ground_segment(segment_length, terrain_type)
	segments.append(segment)
	
	# Update positions
	last_segment_end += segment_width * float(segment_length)
	current_height = target_height

func choose_terrain_type() -> String:
	var rand_val = randf()
	
	if rand_val < 0.4:
		return "normal"
	elif rand_val < 0.6:
		return "hill"
	elif rand_val < 0.75:
		return "valley"
	elif rand_val < 0.85:
		return "plateau"
	else:
		return "bumpy"

func calculate_height_change(terrain_type: String) -> float:
	match terrain_type:
		"normal":
			return randf_range(-max_height_variation * 0.5, max_height_variation * 0.5)
		"hill":
			return randf_range(max_height_variation * 0.3, max_height_variation * 0.8)
		"valley":
			return randf_range(-max_height_variation * 0.8, -max_height_variation * 0.3)
		"plateau":
			return randf_range(-max_height_variation * 0.2, max_height_variation * 0.2)
		"bumpy":
			return randf_range(-max_height_variation * 0.6, max_height_variation * 0.6)
		_:
			return 0.0

func create_ground_segment(length: int, terrain_type: String) -> Node2D:
	var segment = Node2D.new()
	segment.name = "GroundSegment_" + str(segments.size())
	
	# Create multiple ground pieces for this segment
	for i in range(length):
		var ground_piece = create_ground_piece(i, length, terrain_type)
		segment.add_child(ground_piece)
	
	segment.position = Vector2(last_segment_end, 0)
	add_child(segment)
	
	return segment

func create_ground_piece(index: int, total_length: int, terrain_type: String) -> StaticBody2D:
	var ground_piece = StaticBody2D.new()
	ground_piece.name = "GroundPiece_" + str(index)
	
	# Calculate height for this piece based on terrain type
	var piece_height = calculate_piece_height(index, total_length, terrain_type)
	
	# Create collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(segment_width, ground_height)
	collision.shape = shape
	collision.position = Vector2(0, piece_height - ground_height/2)
	ground_piece.add_child(collision)
	
	# Create visual representation
	var visual = create_ground_visual(piece_height, terrain_type)
	ground_piece.add_child(visual)
	
	# Position the piece
	ground_piece.position = Vector2(index * segment_width, 0)
	
	return ground_piece

func calculate_piece_height(index: int, total_length: int, terrain_type: String) -> float:
	var progress = float(index) / float(total_length - 1) if total_length > 1 else 0.0
	
	match terrain_type:
		"normal":
			return lerp(float(current_height), float(target_height), smoothness * progress)
		"hill":
			# Create a hill shape (parabolic)
			var hill_factor = 4.0 * progress * (1.0 - progress)  # Creates a hill shape
			return lerp(float(current_height), float(target_height), hill_factor)
		"valley":
			# Create a valley shape (inverted parabolic)
			var valley_factor = 1.0 - 4.0 * progress * (1.0 - progress)  # Creates a valley shape
			return lerp(float(current_height), float(target_height), valley_factor)
		"plateau":
			# Create a flat plateau with smooth edges
			var plateau_factor = smoothstep(0.2, 0.8, progress)
			return lerp(float(current_height), float(target_height), plateau_factor)
		"bumpy":
			# Create bumpy terrain with noise
			var noise_factor = sin(progress * PI * 2.0) * 0.3
			return lerp(float(current_height), float(target_height), smoothness * progress) + noise_factor * 30.0
		_:
			return lerp(float(current_height), float(target_height), smoothness * progress)

func create_ground_visual(height: float, terrain_type: String) -> Node2D:
	var visual_container = Node2D.new()
	
	# Create main ground rectangle
	var main_ground = ColorRect.new()
	main_ground.size = Vector2(segment_width, ground_height)
	main_ground.position = Vector2(-segment_width/2, height - ground_height)
	
	# Set color based on height and terrain type
	var color = calculate_ground_color(height, terrain_type)
	main_ground.color = color
	
	visual_container.add_child(main_ground)
	
	# Add terrain-specific visual details
	add_terrain_details(visual_container, height, terrain_type)
	
	return visual_container

func calculate_ground_color(height: float, terrain_type: String) -> Color:
	var height_factor = (height - 400.0) / 200.0  # Normalize to 0-1
	height_factor = clamp(height_factor, 0.0, 1.0)
	
	var base_green = lerp(0.3, 0.8, height_factor)
	var base_blue = lerp(0.1, 0.4, height_factor)
	var base_red = 0.2
	
	match terrain_type:
		"normal":
			return Color(base_red, base_green, base_blue, 1.0)
		"hill":
			# Hills are slightly more brown
			return Color(base_red + 0.1, base_green - 0.1, base_blue - 0.05, 1.0)
		"valley":
			# Valleys are darker and more green
			return Color(base_red - 0.05, base_green + 0.1, base_blue + 0.05, 1.0)
		"plateau":
			# Plateaus are lighter
			return Color(base_red + 0.05, base_green + 0.05, base_blue + 0.05, 1.0)
		"bumpy":
			# Bumpy terrain has more variation
			var variation = sin(height * 0.1) * 0.1
			return Color(base_red + variation, base_green + variation, base_blue + variation, 1.0)
		_:
			return Color(base_red, base_green, base_blue, 1.0)

func add_terrain_details(container: Node2D, height: float, terrain_type: String):
	match terrain_type:
		"hill":
			# Add some rocks or texture to hills
			if randf() < 0.3:
				add_rock_detail(container, height)
		"valley":
			# Add grass or vegetation to valleys
			if randf() < 0.4:
				add_grass_detail(container, height)
		"plateau":
			# Add some flat texture
			if randf() < 0.2:
				add_plateau_detail(container, height)
		"bumpy":
			# Add random small details
			if randf() < 0.5:
				add_random_detail(container, height)

func add_rock_detail(container: Node2D, height: float):
	var rock = ColorRect.new()
	rock.size = Vector2(randf_range(10, 30), randf_range(10, 20))
	rock.position = Vector2(randf_range(-segment_width/3, segment_width/3), height - ground_height - rock.size.y)
	rock.color = Color(0.4, 0.4, 0.4, 1.0)
	container.add_child(rock)

func add_grass_detail(container: Node2D, height: float):
	var grass = ColorRect.new()
	grass.size = Vector2(randf_range(5, 15), randf_range(8, 15))
	grass.position = Vector2(randf_range(-segment_width/3, segment_width/3), height - ground_height - grass.size.y)
	grass.color = Color(0.1, 0.6, 0.1, 1.0)
	container.add_child(grass)

func add_plateau_detail(container: Node2D, height: float):
	var detail = ColorRect.new()
	detail.size = Vector2(randf_range(20, 40), 3)
	detail.position = Vector2(randf_range(-segment_width/3, segment_width/3), height - ground_height - 5)
	detail.color = Color(0.3, 0.5, 0.2, 1.0)
	container.add_child(detail)

func add_random_detail(container: Node2D, height: float):
	var detail_types = ["rock", "grass", "plateau"]
	var detail_type = detail_types[randi() % detail_types.size()]
	
	match detail_type:
		"rock":
			add_rock_detail(container, height)
		"grass":
			add_grass_detail(container, height)
		"plateau":
			add_plateau_detail(container, height)

func cleanup_old_segments():
	# Remove segments that are far behind the player
	var player_x = player.position.x
	var segments_to_remove = []
	
	for segment in segments:
		if segment.position.x + segment_width * max_segment_length < player_x - 500:
			segments_to_remove.append(segment)
	
	for segment in segments_to_remove:
		segments.erase(segment)
		segment.queue_free()

# Function to get current ground height at a specific x position
func get_ground_height_at(x: float) -> float:
	# Find the segment that contains this x position
	for segment in segments:
		var segment_start = segment.position.x
		var segment_end = segment_start + segment_width * max_segment_length
		
		if x >= segment_start and x < segment_end:
			# Calculate relative position within segment
			var relative_x = x - segment_start
			var piece_index = int(relative_x / segment_width)
			
			if piece_index < segment.get_child_count():
				var piece = segment.get_child(piece_index)
				if piece.has_method("get_ground_height"):
					return piece.get_ground_height()
	
	# Default height if no segment found
	return 500.0 
