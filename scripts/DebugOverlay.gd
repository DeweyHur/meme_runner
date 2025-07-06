extends CanvasLayer

@onready var player = get_parent().get_node("Player")
@onready var procedural_ground = get_parent().get_node("ProceduralGround")

var player_debug_label: Label
var ground_debug_label: Label
var debug_visible = true

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

func update_player_debug_info():
	if not player:
		return
	
	# Get player position in screen coordinates
	var player_screen_pos = get_viewport().get_camera_2d().get_screen_center_position()
	player_screen_pos.y -= 150  # Position above player
	
	# Update label position
	player_debug_label.position = player_screen_pos
	
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
		player_info += "Floor Normal: (%.2f, %.2f)\n" % [floor_normal.x, floor_normal.y]
		
		# Calculate slope angle
		var slope_angle = acos(floor_normal.y)
		var slope_degrees = slope_angle * 180.0 / PI
		player_info += "Slope Angle: %.1f°\n" % slope_degrees
		
		# Show debug info from player
		if player.debug_info.has("slope_type"):
			player_info += "Slope Type: %s\n" % player.debug_info["slope_type"]
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
	
	# Get current terrain type if available
	if procedural_ground.segments.size() > 0:
		var last_segment = procedural_ground.segments[-1]
		ground_info += "Last Segment Type: %s\n" % last_segment.name
		
		# Show height difference info
		var height_diff = procedural_ground.target_height - procedural_ground.current_height
		ground_info += "Height Difference: %.1f\n" % height_diff
		if abs(height_diff) < procedural_ground.walkable_height_threshold:
			ground_info += "Status: Walkable Slope\n"
		else:
			ground_info += "Status: Jump Required\n"
	
	# Position ground debug label at bottom of screen
	var viewport_size = get_viewport().get_visible_rect().size
	ground_debug_label.position = Vector2(10, viewport_size.y - 150)
	
	# Update label text
	ground_debug_label.text = ground_info 
