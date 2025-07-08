extends CanvasLayer

@onready var player = get_parent().get_node("Player")
@onready var procedural_ground = get_parent().get_node("ProceduralGround")

var player_debug_label: Label
var ground_debug_label: Label
var bullet_debug_label: Label
var debug_visible = false

func _ready():
	# Create player debug label
	player_debug_label = Label.new()
	player_debug_label.name = "PlayerDebugLabel"
	player_debug_label.add_theme_font_size_override("font_size", 14)
	player_debug_label.add_theme_color_override("font_color", Color.YELLOW)
	player_debug_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	player_debug_label.add_theme_constant_override("shadow_offset_x", 1)
	player_debug_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(player_debug_label)
	
	# Create ground debug label
	ground_debug_label = Label.new()
	ground_debug_label.name = "GroundDebugLabel"
	ground_debug_label.add_theme_font_size_override("font_size", 12)
	ground_debug_label.add_theme_color_override("font_color", Color.CYAN)
	ground_debug_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	ground_debug_label.add_theme_constant_override("shadow_offset_x", 1)
	ground_debug_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(ground_debug_label)
	
	# Create bullet debug label
	bullet_debug_label = Label.new()
	bullet_debug_label.name = "BulletDebugLabel"
	bullet_debug_label.add_theme_font_size_override("font_size", 12)
	bullet_debug_label.add_theme_color_override("font_color", Color.ORANGE)
	bullet_debug_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	bullet_debug_label.add_theme_constant_override("shadow_offset_x", 1)
	bullet_debug_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(bullet_debug_label)
	
	# Create toggle instruction label
	var toggle_label = Label.new()
	toggle_label.name = "ToggleLabel"
	toggle_label.text = "Press F1 to toggle debug info"
	toggle_label.add_theme_font_size_override("font_size", 16)
	toggle_label.add_theme_color_override("font_color", Color.WHITE)
	toggle_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	toggle_label.add_theme_constant_override("shadow_offset_x", 1)
	toggle_label.add_theme_constant_override("shadow_offset_y", 1)
	toggle_label.position = Vector2(10, 10)
	add_child(toggle_label)
	
	# Set initial visibility
	player_debug_label.visible = debug_visible
	ground_debug_label.visible = debug_visible
	bullet_debug_label.visible = debug_visible

func _process(delta):
	if not player:
		return
	
	# Handle F1 toggle
	if Input.is_action_just_pressed("ui_focus_next"):  # F1 key
		debug_visible = !debug_visible
		player_debug_label.visible = debug_visible
		ground_debug_label.visible = debug_visible
	
	if debug_visible:
		update_player_debug_info()
		update_ground_debug_info()
		update_bullet_debug_info()

func update_player_debug_info():
	if not player:
		return
	
	# Use fixed position for player debug info (top-right corner)
	player_debug_label.position = Vector2(10, 50)
	
	# Get player information
	var player_info = ""
	player_info += "Player Status:\n"
	player_info += "Position: (%.1f, %.1f)\n" % [player.position.x, player.position.y]
	player_info += "Velocity: (%.1f, %.1f)\n" % [player.velocity.x, player.velocity.y]
	player_info += "Speed: %.1f\n" % player.velocity.length()
	player_info += "On Floor: %s\n" % str(player.is_on_floor())
	player_info += "Is Jumping: %s\n" % str(player.is_jumping)
	player_info += "Is Sliding: %s\n" % str(player.is_sliding)
	
	# Get floor normal if on floor
	if player.is_on_floor():
		var floor_normal = player.get_floor_normal()
		player_info += "Floor Normal: (%.3f, %.3f)\n" % [floor_normal.x, floor_normal.y]
		
		# Show detailed floor normal info from player debug
		if player.debug_info.has("floor_normal_x"):
			player_info += "Debug Normal: (%.3f, %.3f)\n" % [player.debug_info["floor_normal_x"], player.debug_info["floor_normal_y"]]
		if player.debug_info.has("floor_normal_length"):
			player_info += "Normal Length: %.3f\n" % player.debug_info["floor_normal_length"]
		
		# Calculate slope angle
		var slope_angle = acos(floor_normal.y)
		var slope_degrees = slope_angle * 180.0 / PI
		player_info += "Slope Angle: %.1f°\n" % slope_degrees
		
		# Show debug info from player
		if player.debug_info.has("slope_type"):
			player_info += "Slope Type: %s\n" % player.debug_info["slope_type"]
		if player.debug_info.has("invalid_reason"):
			player_info += "Invalid Reason: %s\n" % player.debug_info["invalid_reason"]
		if player.debug_info.has("slope_velocity"):
			player_info += "Slope Velocity: %.1f\n" % player.debug_info["slope_velocity"]
		
		# Determine terrain type based on slope
		if slope_angle < 0.1:  # Less than ~6 degrees
			player_info += "Terrain: Flat\n"
		elif slope_angle < 0.785398:  # Less than 45 degrees
			player_info += "Terrain: Walkable Slope\n"
		else:
			player_info += "Terrain: Steep Slope\n"
	
	# Get collision information
	player_info += "Collisions: %d\n" % player.get_slide_collision_count()
	
	# Check for obstacle collisions
	var obstacle_collision = false
	for i in player.get_slide_collision_count():
		var collision = player.get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("obstacles"):
			obstacle_collision = true
			break
	
	player_info += "Obstacle Collision: %s\n" % str(obstacle_collision)
	
	# Show stuck timer if active
	if player.debug_info.has("stuck_timer") and player.debug_info["stuck_timer"] > 0.0:
		player_info += "Stuck Timer: %.1fs\n" % player.debug_info["stuck_timer"]
	
	# Show collision setup info
	if player.debug_info.has("collision_layer"):
		player_info += "Collision Layer: %d\n" % player.debug_info["collision_layer"]
	if player.debug_info.has("collision_mask"):
		player_info += "Collision Mask: %d\n" % player.debug_info["collision_mask"]
	if player.debug_info.has("ground_collision"):
		player_info += "Ground Collision: %s\n" % str(player.debug_info["ground_collision"])
	if player.debug_info.has("ground_collider_name"):
		player_info += "Ground Collider: %s\n" % player.debug_info["ground_collider_name"]
	
	# Update label text
	player_debug_label.text = player_info

func update_ground_debug_info():
	if not procedural_ground:
		return
	
	# Get ground information
	var ground_info = ""
	ground_info += "Ground Info:\n"
	ground_info += "Segments: %d\n" % procedural_ground.segments.size()
	ground_info += "Current Height: %.1f\n" % procedural_ground.current_height
	ground_info += "Target Height: %.1f\n" % procedural_ground.target_height
	ground_info += "Last Segment End: %.1f\n" % procedural_ground.last_segment_end
	
	# Get player position for ground height calculation
	if player:
		var ground_height_at_player = procedural_ground.get_ground_height_at(player.position.x)
		ground_info += "Ground Height at Player: %.1f\n" % ground_height_at_player
		ground_info += "Player Distance from Ground: %.1f\n" % (player.position.y - ground_height_at_player)
	
	# Show detailed segment information
	ground_info += "\nSegment Details:\n"
	
	# Show last 5 segments (most relevant)
	var segments_to_show = min(5, procedural_ground.segments.size())
	var start_index = max(0, procedural_ground.segments.size() - segments_to_show)
	
	for i in range(start_index, procedural_ground.segments.size()):
		var segment = procedural_ground.segments[i]
		ground_info += "Segment %d: %s\n" % [i, segment.name]
		ground_info += "  Position: (%.1f, %.1f)\n" % [segment.position.x, segment.position.y]
		ground_info += "  Pieces: %d\n" % segment.get_child_count()
		
		# Show piece details for this segment
		for j in range(min(3, segment.get_child_count())):  # Show first 3 pieces
			var piece = segment.get_child(j)
			if piece is StaticBody2D:
				ground_info += "    Piece %d: (%.1f, %.1f)\n" % [j, piece.position.x, piece.position.y]
				
				# Find collision shape
				for child in piece.get_children():
					if child is CollisionShape2D:
						ground_info += "      Collision: (%.1f, %.1f)\n" % [child.position.x, child.position.y]
						if child.shape and child.shape is RectangleShape2D:
							var rect = child.shape as RectangleShape2D
							ground_info += "      Size: (%.1f, %.1f)\n" % [rect.size.x, rect.size.y]
							# Calculate actual ground Y position
							var actual_ground_y = segment.position.y + piece.position.y + child.position.y - rect.size.y/2
							ground_info += "      Ground Y: %.1f\n" % actual_ground_y
						break
		
		# Show terrain type if available
		if segment.name.contains("uphill"):
			ground_info += "  Type: Uphill Slope\n"
		elif segment.name.contains("downhill"):
			ground_info += "  Type: Downhill Slope\n"
		elif segment.name.contains("hill"):
			ground_info += "  Type: Hill\n"
		elif segment.name.contains("valley"):
			ground_info += "  Type: Valley\n"
		elif segment.name.contains("plateau"):
			ground_info += "  Type: Plateau\n"
		elif segment.name.contains("bumpy"):
			ground_info += "  Type: Bumpy\n"
		else:
			ground_info += "  Type: Normal\n"
		
		ground_info += "\n"
	
	# Get current terrain type if available
	if procedural_ground.segments.size() > 0:
		var last_segment = procedural_ground.segments[-1]
		
		# Show height difference info
		var height_diff = procedural_ground.target_height - procedural_ground.current_height
		ground_info += "Height Difference: %.1f\n" % height_diff
		if abs(height_diff) < procedural_ground.walkable_height_threshold:
			ground_info += "Status: Walkable Slope\n"
			ground_info += "Validation: Should be walkable\n"
		else:
			ground_info += "Status: Jump Required\n"
			ground_info += "Validation: Height exceeds threshold\n"
	
	# Position ground debug label at fixed position (middle-left of screen)
	var viewport_size = get_viewport().get_visible_rect().size
	ground_debug_label.position = Vector2(viewport_size.x - 400, 10)
	
	# Update label text
	ground_debug_label.text = ground_info

func update_bullet_debug_info():
	# Get bullet information
	var bullet_info = ""
	bullet_info += "Bullet Collision Debug:\n"
	
	# Count active bullets
	var active_bullets = 0
	var player_bullets = 0
	var turret_bullets = 0
	
	# Find all bullets in the scene
	var bullets = get_tree().get_nodes_in_group("bullets")
	if bullets.size() == 0:
		# Try to find bullets by checking all Area2D nodes
		for node in get_tree().get_nodes_in_group(""):
			if node is Area2D and node.has_method("get_debug_info"):
				bullets.append(node)
	
	for bullet in bullets:
		if bullet.has_method("get_debug_info"):
			active_bullets += 1
			if bullet.bullet_type == "player":
				player_bullets += 1
			elif bullet.bullet_type == "turret":
				turret_bullets += 1
	
	bullet_info += "Active Bullets: %d\n" % active_bullets
	bullet_info += "Player Bullets: %d\n" % player_bullets
	bullet_info += "Turret Bullets: %d\n" % turret_bullets
	
	# Count and show turret information
	var turrets = get_tree().get_nodes_in_group("enemies")
	var turret_count = 0
	for turret in turrets:
		if turret.name.contains("Turret"):
			turret_count += 1
	
	bullet_info += "Active Turrets: %d\n" % turret_count
	
	# Show recent collision events (this would need to be tracked)
	bullet_info += "\nCollision Rules:\n"
	bullet_info += "✅ Player bullets → Enemies\n"
	bullet_info += "✅ Turret bullets → Player\n"
	bullet_info += "❌ Player bullets → Player\n"
	bullet_info += "❌ Turret bullets → Enemies\n"
	
	# Position bullet debug label at bottom-left
	var viewport_size = get_viewport().get_visible_rect().size
	bullet_debug_label.position = Vector2(10, viewport_size.y - 200)
	
	# Update label text
	bullet_debug_label.text = bullet_info 
