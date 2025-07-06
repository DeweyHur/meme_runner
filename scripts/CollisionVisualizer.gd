extends Node2D

@onready var player = get_parent().get_node("Player")
@onready var procedural_ground = get_parent().get_node("ProceduralGround")

var collision_lines: Array[Line2D] = []
var normal_lines: Array[Line2D] = []
var player_collision_line: Line2D
var player_normal_line: Line2D
var debug_visible = true

func _ready():
	# Create player collision visualization
	player_collision_line = Line2D.new()
	player_collision_line.width = 2.0
	player_collision_line.default_color = Color.RED
	player_collision_line.z_index = 100
	add_child(player_collision_line)
	
	# Create player normal visualization
	player_normal_line = Line2D.new()
	player_normal_line.width = 3.0
	player_normal_line.default_color = Color.YELLOW
	player_normal_line.z_index = 101
	add_child(player_normal_line)
	
	# Create toggle instruction
	var toggle_label = Label.new()
	toggle_label.name = "CollisionToggleLabel"
	toggle_label.text = "Press F2 to toggle collision visualization"
	toggle_label.add_theme_font_size_override("font_size", 14)
	toggle_label.add_theme_color_override("font_color", Color.WHITE)
	toggle_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	toggle_label.add_theme_constant_override("shadow_offset_x", 1)
	toggle_label.add_theme_constant_override("shadow_offset_y", 1)
	toggle_label.position = Vector2(10, 30)
	add_child(toggle_label)

func _process(delta):
	if not player:
		return
	
	# Handle F2 toggle
	if Input.is_action_just_pressed("ui_focus_prev"):  # F2 key
		debug_visible = !debug_visible
		player_collision_line.visible = debug_visible
		player_normal_line.visible = debug_visible
		for line in collision_lines:
			line.visible = debug_visible
		for line in normal_lines:
			line.visible = debug_visible
	
	if debug_visible:
		update_player_collision_visualization()
		update_ground_collision_visualization()

func update_player_collision_visualization():
	if not player:
		return
	
	# Get player collision shape
	var collision_shape = null
	for child in player.get_children():
		if child is CollisionShape2D:
			collision_shape = child
			break
	
	if collision_shape and collision_shape.shape:
		# Draw player collision box
		var points = []
		if collision_shape.shape is RectangleShape2D:
			var rect = collision_shape.shape as RectangleShape2D
			var size = rect.size
			var pos = player.position + collision_shape.position
			
			# Create rectangle points
			points = [
				pos + Vector2(-size.x/2, -size.y/2),  # Top-left
				pos + Vector2(size.x/2, -size.y/2),   # Top-right
				pos + Vector2(size.x/2, size.y/2),    # Bottom-right
				pos + Vector2(-size.x/2, size.y/2),   # Bottom-left
				pos + Vector2(-size.x/2, -size.y/2)   # Back to start
			]
		
		player_collision_line.points = points
		
		# Draw floor normal if on floor
		if player.is_on_floor():
			var floor_normal = player.get_floor_normal()
			var normal_start = player.position
			var normal_end = normal_start + floor_normal * 50.0  # 50 pixel normal line
			
			player_normal_line.points = [normal_start, normal_end]
			player_normal_line.visible = true
			
			# Add arrowhead to normal
			var arrow_points = create_arrowhead(normal_start, normal_end, 10.0)
			player_normal_line.points.append_array(arrow_points)
		else:
			player_normal_line.visible = false

func update_ground_collision_visualization():
	if not procedural_ground:
		return
	
	# Clear old ground collision lines
	for line in collision_lines:
		line.queue_free()
	collision_lines.clear()
	
	for line in normal_lines:
		line.queue_free()
	normal_lines.clear()
	
	# Draw collision boxes for visible ground segments
	var camera = get_parent().get_node("Camera2D")
	if not camera:
		return
	
	var viewport_size = get_viewport().get_visible_rect().size
	var camera_left = camera.position.x - viewport_size.x/2
	var camera_right = camera.position.x + viewport_size.x/2
	
	for segment in procedural_ground.segments:
		# Only draw segments that are visible
		var segment_start = segment.position.x
		var segment_end = segment_start + procedural_ground.segment_width * procedural_ground.max_segment_length
		
		if segment_end < camera_left or segment_start > camera_right:
			continue
		
		# Draw collision boxes for each ground piece in the segment
		for i in range(segment.get_child_count()):
			var piece = segment.get_child(i)
			if piece is StaticBody2D:
				draw_ground_piece_collision(piece, segment.position)

func draw_ground_piece_collision(piece: StaticBody2D, segment_position: Vector2):
	# Find collision shape
	var collision_shape = null
	for child in piece.get_children():
		if child is CollisionShape2D:
			collision_shape = child
			break
	
	if collision_shape and collision_shape.shape:
		# Create collision line
		var collision_line = Line2D.new()
		collision_line.width = 1.0
		collision_line.default_color = Color.GREEN
		collision_line.z_index = 50
		add_child(collision_line)
		collision_lines.append(collision_line)
		
		# Draw collision polygon (ConvexPolygonShape2D)
		if collision_shape.shape is ConvexPolygonShape2D:
			var poly = collision_shape.shape as ConvexPolygonShape2D
			var points = []
			for p in poly.points:
				points.append(segment_position + piece.position + collision_shape.position + p)
			# Close the polygon
			if points.size() > 0:
				points.append(points[0])
			collision_line.points = points
			
			# Draw normal at the center of the top edge (between first two points)
			if points.size() >= 2:
				var top_left = points[0]
				var top_right = points[1]
				var edge_center = (top_left + top_right) / 2.0
				var edge_dir = (top_right - top_left).normalized()
				var normal = Vector2(-edge_dir.y, edge_dir.x).normalized()  # Perpendicular
				# Ensure normal points "upward" (away from ground)
				if normal.y > 0:
					normal = -normal
				var normal_end = edge_center + normal * 30.0
				
				var normal_line = Line2D.new()
				normal_line.width = 2.0
				normal_line.default_color = Color.BLUE
				normal_line.z_index = 51
				add_child(normal_line)
				normal_lines.append(normal_line)
				normal_line.points = [edge_center, normal_end]
				# Add arrowhead
				var arrow_points = create_arrowhead(edge_center, normal_end, 8.0)
				normal_line.points.append_array(arrow_points)

func create_arrowhead(start: Vector2, end: Vector2, size: float) -> Array[Vector2]:
	var direction = (end - start).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	
	var arrow_tip = end
	var arrow_left = end - direction * size + perpendicular * size/2
	var arrow_right = end - direction * size - perpendicular * size/2
	
	return [arrow_left, arrow_tip, arrow_right] 