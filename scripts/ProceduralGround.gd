extends Node2D

@export var segment_width = 200.0
@export var ground_height = 50.0
@export var max_height_variation = 100.0
@export var min_segment_length = 3
@export var max_segment_length = 8
@export var smoothness = 0.3  # How smooth the transitions are (0-1)
@export var terrain_complexity = 0.7  # How complex the terrain should be
@export var max_walkable_slope = 25.0  # Maximum slope angle in degrees that player can walk up
@export var slope_segment_length = 6  # How many segments to use for gradual slopes
@export var walkable_height_threshold = 120.0  # Height difference threshold for walkable slopes

var player: Node2D
var last_segment_end = 0.0
var current_height = 500.0
var target_height = 500.0
var segments: Array[Node2D] = []
var max_segments = 20  # Keep only this many segments in memory
var terrain_seed = 0

func _ready():
	# Try multiple ways to find the player
	player = get_parent().get_node("Player")
	if not player:
		# Try finding by class
		var potential_players = get_tree().get_nodes_in_group("player")
		if potential_players.size() > 0:
			player = potential_players[0]
		else:
			# Try finding by script
			var all_nodes = get_tree().get_nodes_in_group("")
			for node in all_nodes:
				if node.has_method("get_velocity") and node is CharacterBody2D:
					player = node
					break
	
	if not player:
		push_error("Player not found!")
		return
	
	# Set random seed for consistent terrain generation
	terrain_seed = randi()
	seed(terrain_seed)
	
	# Generate initial ground
	generate_initial_ground()

func _process(delta):
	# Check if player reference is still valid
	if not player or not is_instance_valid(player):
		player = get_parent().get_node("Player")
		if not player:
			var potential_players = get_tree().get_nodes_in_group("player")
			if potential_players.size() > 0:
				player = potential_players[0]
			else:
				return
	
	if not player:
		return
	
	# Check if we need to generate more ground
	var player_x = player.position.x
	
	if player_x + 1000 > last_segment_end:
		# Check if we're at the segment limit
		if segments.size() >= max_segments:
			# Force cleanup of old segments
			cleanup_old_segments()
		
		# Only generate if we're under the limit
		if segments.size() < max_segments:
			generate_next_segment()
	
	# Clean up old segments
	cleanup_old_segments()

func generate_initial_ground():
	# Generate a few segments to start
	for i in range(5):
		generate_next_segment()

func generate_next_segment():
	# Generate terrain type first
	var terrain_type = choose_terrain_type()
	
	# Generate height change
	var height_change = calculate_height_change(terrain_type)
	
	# Convert small height changes to walkable slopes
	var adjusted_terrain_type = convert_to_walkable_slope(height_change)
	if adjusted_terrain_type != "normal":
		terrain_type = adjusted_terrain_type
	
	# Determine segment length based on terrain type
	var segment_length = get_segment_length_for_terrain(terrain_type)
	
	target_height = float(current_height) + float(height_change)
	
	# Clamp height to reasonable bounds
	target_height = clamp(target_height, 400.0, 600.0)
	
	# Final validation: if height difference is small, force walkable slope
	var final_height_diff = abs(target_height - current_height)
	if final_height_diff < walkable_height_threshold:
		# Recalculate terrain type based on final height difference
		if target_height > current_height:
			terrain_type = "uphill"
		else:
			terrain_type = "downhill"
		
		# Adjust segment length for slopes
		segment_length = slope_segment_length
	
	# Create the segment
	var segment = create_ground_segment(segment_length, terrain_type)
	
	# Validate the segment
	validate_ground_segment(segment, terrain_type)
	
	segments.append(segment)
	
	# Update positions
	last_segment_end += segment_width * float(segment_length)
	current_height = target_height

func choose_terrain_type() -> String:
	var rand_val = randf()
	
	if rand_val < 0.4:
		return "normal"
	elif rand_val < 0.55:
		return "uphill"
	elif rand_val < 0.7:
		return "downhill"
	elif rand_val < 0.75:
		return "hill"
	elif rand_val < 0.8:
		return "valley"
	elif rand_val < 0.9:
		return "plateau"
	else:
		return "bumpy"

func get_segment_length_for_terrain(terrain_type: String) -> int:
	match terrain_type:
		"uphill", "downhill":
			# Use longer segments for slopes to make them more gradual
			return slope_segment_length
		"hill", "valley":
			# Use medium segments for hills and valleys
			return randi_range(min_segment_length + 1, max_segment_length - 1)
		"plateau":
			# Use longer segments for plateaus
			return randi_range(max_segment_length - 2, max_segment_length)
		"normal", "bumpy":
			# Use standard segment length for normal and bumpy terrain
			return randi_range(min_segment_length, max_segment_length)
		_:
			return randi_range(min_segment_length, max_segment_length)

func calculate_height_change(terrain_type: String) -> float:
	match terrain_type:
		"normal":
			return randf_range(-max_height_variation * 0.3, max_height_variation * 0.3)
		"uphill":
			# Calculate walkable uphill slope
			var slope_angle = randf_range(10.0, max_walkable_slope)
			var slope_distance = segment_width * slope_segment_length
			return slope_distance * tan(deg_to_rad(slope_angle))
		"downhill":
			# Calculate walkable downhill slope
			var slope_angle = randf_range(10.0, max_walkable_slope)
			var slope_distance = segment_width * slope_segment_length
			return -slope_distance * tan(deg_to_rad(slope_angle))
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

func convert_to_walkable_slope(height_change: float) -> String:
	# If height difference is small, convert to walkable slope
	if abs(height_change) < walkable_height_threshold:
		if height_change > 0:
			return "uphill"
		else:
			return "downhill"
	return "normal"

func validate_ground_segment(segment: Node2D, terrain_type: String):
	# Validate that the segment has proper collision setup
	for i in range(segment.get_child_count()):
		var piece = segment.get_child(i)
		if piece is StaticBody2D:
			# Ensure collision layer is set correctly
			piece.collision_layer = 1
			piece.collision_mask = 0
			
			# Check collision shape
			for j in range(piece.get_child_count()):
				var child = piece.get_child(j)
				if child is CollisionShape2D:
					# Ensure collision shape is valid
					if child.shape:
						pass  # Validation successful

func create_ground_segment(length: int, terrain_type: String) -> Node2D:
	var segment = Node2D.new()
	segment.name = "GroundSegment_" + str(segments.size())

	# Precompute edge heights (N+1 for N pieces)
	var edge_heights = []
	for i in range(length + 1):
		var progress = float(i) / float(length)
		var edge_height = calculate_edge_height(progress, terrain_type)
		edge_heights.append(edge_height)

	# Create ground pieces using edge heights
	for i in range(length):
		var ground_piece = create_ground_piece_with_edges(i, length, terrain_type, edge_heights)
		segment.add_child(ground_piece)

	# Validate all piece connections after all pieces are created
	for i in range(length):
		var piece = segment.get_child(i)
		if piece is StaticBody2D:
			validate_piece_connection(piece, i, length, edge_heights[i], edge_heights[i+1])

	segment.position = Vector2(last_segment_end, 0)
	add_child(segment)
	return segment

func calculate_edge_height(progress: float, terrain_type: String) -> float:
	# Use your existing logic for terrain types, but with progress in [0,1]
	match terrain_type:
		"normal":
			return lerp(float(current_height), float(target_height), smoothness * progress)
		"uphill":
			return lerp(float(current_height), float(target_height), progress)
		"downhill":
			return lerp(float(current_height), float(target_height), progress)
		"hill":
			var hill_factor = 4.0 * progress * (1.0 - progress)
			return lerp(float(current_height), float(target_height), hill_factor)
		"valley":
			var valley_factor = 1.0 - 4.0 * progress * (1.0 - progress)
			return lerp(float(current_height), float(target_height), valley_factor)
		"plateau":
			var plateau_factor = smoothstep(0.2, 0.8, progress)
			return lerp(float(current_height), float(target_height), plateau_factor)
		"bumpy":
			var noise_factor = sin(progress * PI * 2.0) * 0.3
			return lerp(float(current_height), float(target_height), smoothness * progress) + noise_factor * 30.0
		_:
			return lerp(float(current_height), float(target_height), smoothness * progress)

func create_ground_piece_with_edges(index: int, total_length: int, terrain_type: String, edge_heights: Array) -> StaticBody2D:
	var ground_piece = StaticBody2D.new()
	ground_piece.name = "GroundPiece_" + str(index)
	ground_piece.collision_layer = 1
	ground_piece.collision_mask = 0

	var left_height = edge_heights[index]
	var right_height = edge_heights[index+1]

	# Create sloped collision shape
	var collision = CollisionShape2D.new()
	var shape = create_sloped_collision_shape(left_height, right_height, index, total_length)
	collision.shape = shape
	collision.position = Vector2(0, 0)
	ground_piece.add_child(collision)
	print("Created collision shape for piece %d with points: %s" % [index, str(shape.points) if shape is ConvexPolygonShape2D else "N/A"])

	# Create visual representation
	var visual = create_sloped_ground_visual(left_height, right_height, index, total_length, terrain_type)
	ground_piece.add_child(visual)

	ground_piece.position = Vector2(index * segment_width, 0)
	print("Created ground piece %d, left: %.2f, right: %.2f" % [index, left_height, right_height])
	
	# Add method to get ground height
	ground_piece.set_script(load("res://scripts/GroundPiece.gd"))
	ground_piece.left_height = left_height
	ground_piece.right_height = right_height
	
	return ground_piece

func create_sloped_collision_shape(left_height: float, right_height: float, index: int, total_length: int) -> Shape2D:
	var shape = ConvexPolygonShape2D.new()
	var left_x = -segment_width / 2
	var right_x = segment_width / 2
	var top_left_y = left_height
	var top_right_y = right_height
	var bottom_left_y = left_height + ground_height
	var bottom_right_y = right_height + ground_height
	var points = [
		Vector2(left_x, top_left_y),
		Vector2(right_x, top_right_y),
		Vector2(right_x, bottom_right_y),
		Vector2(left_x, bottom_left_y)
	]
	shape.points = points
	return shape

func create_sloped_ground_visual(left_height: float, right_height: float, index: int, total_length: int, terrain_type: String) -> Node2D:
	var visual_container = Node2D.new()
	var left_x = -segment_width / 2
	var right_x = segment_width / 2
	var top_left_y = left_height
	var top_right_y = right_height
	var bottom_left_y = left_height + ground_height
	var bottom_right_y = right_height + ground_height
	var points = [
		Vector2(left_x, top_left_y),
		Vector2(right_x, top_right_y),
		Vector2(right_x, bottom_right_y),
		Vector2(left_x, bottom_left_y)
	]
	var sloped_ground = Polygon2D.new()
	sloped_ground.polygon = points
	var avg_height = (left_height + right_height) / 2.0
	var color = calculate_ground_color(avg_height, terrain_type)
	sloped_ground.color = color
	visual_container.add_child(sloped_ground)
	add_terrain_details(visual_container, avg_height, terrain_type)
	return visual_container

func validate_piece_connection(piece: StaticBody2D, index: int, total_length: int, left_height: float, right_height: float):
	var tolerance = 1.0
	var collision_shape = null
	for child in piece.get_children():
		if child is CollisionShape2D:
			collision_shape = child
			break
	if not collision_shape or not collision_shape.shape:
		print("WARNING: Piece %d has no collision shape!" % index)
		return
	var points = []
	if collision_shape.shape is ConvexPolygonShape2D:
		var poly = collision_shape.shape as ConvexPolygonShape2D
		points = poly.points
		if poly.points.size() >= 4:
			left_height = poly.points[0].y
			right_height = poly.points[1].y
		else:
			print("WARNING: Piece %d has invalid polygon points!" % index)
			return
	else:
		print("WARNING: Piece %d has non-polygon collision shape!" % index)
		return
	print("[DEBUG] Piece %d: left_height=%.2f, right_height=%.2f, points=%s" % [index, left_height, right_height, str(points)])
	if index > 0:
		var prev_piece = piece.get_parent().get_child(index - 1)
		if prev_piece and prev_piece is StaticBody2D:
			var prev_collision_shape = null
			for child in prev_piece.get_children():
				if child is CollisionShape2D:
					prev_collision_shape = child
					break
			if prev_collision_shape and prev_collision_shape.shape is ConvexPolygonShape2D:
				var prev_poly = prev_collision_shape.shape as ConvexPolygonShape2D
				if prev_poly.points.size() >= 2:
					var prev_right_height = prev_poly.points[1].y
					var diff = abs(prev_right_height - left_height)
					print("[DEBUG] Piece %d: prev_piece right_edge=%.2f, this left_edge=%.2f, diff=%.2f" % [index, prev_right_height, left_height, diff])
					if diff > tolerance:
						print("WARNING: Piece %d left edge (%.2f) doesn't match previous piece right edge (%.2f). Diff: %.2f" % [index, left_height, prev_right_height, diff])
					else:
						print("Piece %d connects properly with previous piece (diff: %.2f)" % [index, diff])
	if index < total_length - 1:
		var next_piece = piece.get_parent().get_child(index + 1)
		if next_piece and next_piece is StaticBody2D:
			var next_collision_shape = null
			for child in next_piece.get_children():
				if child is CollisionShape2D:
					next_collision_shape = child
					break
			if next_collision_shape and next_collision_shape.shape is ConvexPolygonShape2D:
				var next_poly = next_collision_shape.shape as ConvexPolygonShape2D
				if next_poly.points.size() >= 1:
					var next_left_height = next_poly.points[0].y
					var diff = abs(right_height - next_left_height)
					print("[DEBUG] Piece %d: this right_edge=%.2f, next_piece left_edge=%.2f, diff=%.2f" % [index, right_height, next_left_height, diff])
					if diff > tolerance:
						print("WARNING: Piece %d right edge (%.2f) doesn't match next piece left edge (%.2f). Diff: %.2f" % [index, right_height, next_left_height, diff])
					else:
						print("Piece %d connects properly with next piece (diff: %.2f)" % [index, diff])
	if abs(right_height - left_height) > 0.1:
		var slope_angle = atan2(abs(right_height - left_height), segment_width)
		var slope_degrees = slope_angle * 180.0 / PI
		print("Piece %d slope: %.1f degrees (left: %.1f, right: %.1f)" % [index, slope_degrees, left_height, right_height])
		if slope_degrees > 45.0:
			print("WARNING: Piece %d has steep slope: %.1f degrees" % [index, slope_degrees])

func calculate_piece_height(index: int, total_length: int, terrain_type: String) -> float:
	var progress = float(index) / float(total_length - 1) if total_length > 1 else 0.0
	
	match terrain_type:
		"normal":
			return lerp(float(current_height), float(target_height), smoothness * progress)
		"uphill":
			# Create a smooth linear uphill slope
			return lerp(float(current_height), float(target_height), progress)
		"downhill":
			# Create a smooth linear downhill slope
			return lerp(float(current_height), float(target_height), progress)
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
		"uphill":
			# Uphill slopes are slightly darker
			return Color(base_red - 0.05, base_green - 0.05, base_blue - 0.05, 1.0)
		"downhill":
			# Downhill slopes are slightly lighter
			return Color(base_red + 0.05, base_green + 0.05, base_blue + 0.05, 1.0)
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
		"uphill":
			# Add some small rocks on uphill slopes
			if randf() < 0.2:
				add_small_rock_detail(container, height)
		"downhill":
			# Add some grass on downhill slopes
			if randf() < 0.25:
				add_grass_detail(container, height)
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

func add_small_rock_detail(container: Node2D, height: float):
	var rock = ColorRect.new()
	rock.size = Vector2(randf_range(5, 15), randf_range(5, 12))
	rock.position = Vector2(randf_range(-segment_width/3, segment_width/3), height - ground_height - rock.size.y)
	rock.color = Color(0.5, 0.5, 0.5, 1.0)
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
	var detail_types = ["rock", "grass", "plateau", "small_rock"]
	var detail_type = detail_types[randi() % detail_types.size()]
	
	match detail_type:
		"rock":
			add_rock_detail(container, height)
		"grass":
			add_grass_detail(container, height)
		"plateau":
			add_plateau_detail(container, height)
		"small_rock":
			add_small_rock_detail(container, height)

func cleanup_old_segments():
	# Remove segments that are far behind the player
	var player_x = player.position.x
	var segments_to_remove = []
	
	for segment in segments:
		var segment_end = segment.position.x + segment_width * max_segment_length
		var distance_behind = player_x - segment_end
		
		# More aggressive cleanup - remove segments that are 300 units behind player
		if distance_behind > 300:
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
				if piece.has_method("get_ground_height_at_x"):
					# Calculate x offset within the piece
					var piece_x_offset = relative_x - (piece_index * segment_width)
					return piece.get_ground_height_at_x(piece_x_offset)
				elif piece.has_method("get_ground_height"):
					return piece.get_ground_height()
	
	# Default height if no segment found
	return 500.0

# Function to get ground height and normal at a specific x position
func get_ground_info_at(x: float) -> Dictionary:
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
				if piece.has_method("get_ground_info_at_x"):
					# Calculate x offset within the piece
					var piece_x_offset = relative_x - (piece_index * segment_width)
					return piece.get_ground_info_at_x(piece_x_offset)
				elif piece.has_method("get_ground_height"):
					# Fallback to just height with default normal
					return {
						"height": piece.get_ground_height(),
						"normal": Vector2.UP
					}
	
	# Default values if no segment found
	return {"height": 500.0, "normal": Vector2.UP} 
