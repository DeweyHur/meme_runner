extends Control

signal character_selected(character_scene_path: String)

var character_grid: GridContainer
var next_button: Button
var back_button: Button

var selected_character_path: String = ""
var character_cards: Array[Control] = []
var hovered_card: Control = null

# Shared character preview variables
var shared_character_instance: Node = null
var shared_ground: StaticBody2D = null
var shared_viewport: SubViewport = null
var shared_camera: Camera2D = null

# Character data
var characters = [
	{
		"name": "Tung tung tung Sahur",
		"description": "Simple animations\nPerfect for beginners",
		"scene_path": "res://Player/tung.tscn",
		"preview_scene": preload("res://Player/tung.tscn")
	},
	{
		"name": "Tralalero Tralala", 
		"description": "Rich animations with gun variants\nFor experienced players",
		"scene_path": "res://Player/trallo.tscn",
		"preview_scene": preload("res://Player/trallo.tscn")
	},
	{
		"name": "Cappucino Assasino", 
		"description": "Rich animations with gun variants\nFor experienced players",
		"scene_path": "res://Player/trallo.tscn",
		"preview_scene": preload("res://Player/capuccino.tscn")
	},	
]

func _ready():
	setup_character_grid()
	setup_buttons()
	
	# Start with first character selected
	if characters.size() > 0:
		selected_character_path = characters[0]["scene_path"]
		update_next_button_state()
		update_shared_character_preview()
	
	# Start position logging timer
	start_position_logging()

func start_position_logging():
	# Create a timer to log player positions every 5 seconds
	var position_timer = Timer.new()
	add_child(position_timer)
	position_timer.wait_time = 5.0
	position_timer.one_shot = false
	position_timer.timeout.connect(_on_position_log_timer_timeout)
	position_timer.start()
	
	# Store timer reference
	set_meta("position_log_timer", position_timer)

func _on_position_log_timer_timeout():
	log_character_positions()

func log_character_positions():
	print("=== Character Position Log ===")
	
	# Log shared character position
	if shared_character_instance:
		var character_position = shared_character_instance.position
		var character_global_position = shared_character_instance.global_position
		
		print("Shared Character:")
		print("  Character Local Position: ", character_position)
		print("  Character Global Position: ", character_global_position)
		print("  Character Visible: ", shared_character_instance.visible)
		print("  Character Modulate: ", shared_character_instance.modulate)
		
		# Get animated sprite info
		var animated_sprite = shared_character_instance.get_node_or_null("AnimatedSprite2D")
		if animated_sprite:
			print("  AnimatedSprite Frame: ", animated_sprite.frame)
			print("  AnimatedSprite Animation: ", animated_sprite.animation)
			print("  AnimatedSprite Visible: ", animated_sprite.visible)
			print("  AnimatedSprite Flip H: ", animated_sprite.flip_h)
		else:
			print("  AnimatedSprite: Not found")
	else:
		print("Shared Character: Not found!")
	
	# Log card positions
	for i in range(character_cards.size()):
		var card = character_cards[i]
		var character_data = card.get_meta("character_data", {})
		var character_name = character_data.get("name", "Unknown")
		var card_position = card.global_position
		var card_size = card.size
		
		print("Card ", i, " (", character_name, "):")
		print("  Card Global Position: ", card_position)
		print("  Card Size: ", card_size)
		print("  Is Selected: ", card.get_meta("is_selected", false))
	
	print("==============================")

func setup_character_grid():
	# Create the character grid since it's missing from the scene
	var main_container = $MainContainer
	if not main_container:
		print("Error: MainContainer not found!")
		return
	
	# Create shared character preview area
	setup_shared_character_preview(main_container)
	
	# Create the character grid
	character_grid = GridContainer.new()
	character_grid.columns = 3
	character_grid.add_theme_constant_override("h_separation", 40)
	character_grid.add_theme_constant_override("v_separation", 40)
	character_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Add it to the main container after the shared preview
	main_container.add_child(character_grid)
	main_container.move_child(character_grid, 2)  # Move it after the title and shared preview
	
	# Find existing buttons and move them to a proper bottom container
	var existing_back_button = get_node_or_null("MainContainer_BottomContainer#BackButton")
	var existing_next_button = get_node_or_null("MainContainer_BottomContainer#NextButton")
	var existing_spacer = get_node_or_null("MainContainer_BottomContainer#Spacer")
	
	# Create a bottom container for the buttons
	var bottom_container = HBoxContainer.new()
	bottom_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.add_child(bottom_container)
	
	# Move or create back button
	if existing_back_button:
		existing_back_button.get_parent().remove_child(existing_back_button)
		bottom_container.add_child(existing_back_button)
		self.back_button = existing_back_button
	else:
		self.back_button = Button.new()
		self.back_button.text = "Back to Menu"
		self.back_button.custom_minimum_size = Vector2(240, 80)
		self.back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		self.back_button.add_theme_font_size_override("font_size", 16)
		bottom_container.add_child(self.back_button)
	
	# Add spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_container.add_child(spacer)
	
	# Move or create next button
	if existing_next_button:
		existing_next_button.get_parent().remove_child(existing_next_button)
		bottom_container.add_child(existing_next_button)
		self.next_button = existing_next_button
		# Make existing button bigger
		self.next_button.custom_minimum_size = Vector2(300, 100)
		self.next_button.add_theme_font_size_override("font_size", 20)
	else:
		self.next_button = Button.new()
		self.next_button.text = "Next"
		self.next_button.custom_minimum_size = Vector2(300, 100)
		self.next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		self.next_button.add_theme_font_size_override("font_size", 20)
		bottom_container.add_child(self.next_button)
	
	# Remove old spacer if it exists
	if existing_spacer:
		existing_spacer.queue_free()
	
	print("Created new buttons - Back: ", self.back_button != null, " Next: ", self.next_button != null)
	
	# Style the title
	var title = main_container.get_child(0)
	if title and title is Label:
		title.add_theme_font_size_override("font_size", 32)
		title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	
	# Create the character cards
	create_character_cards()

func setup_shared_character_preview(main_container: Control):
	# Create a container for the shared preview area
	var preview_container = Control.new()
	preview_container.name = "SharedPreviewContainer"
	preview_container.custom_minimum_size = Vector2(800, 300)  # Larger area for character preview
	preview_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Add background panel
	var background_panel = Panel.new()
	background_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_panel.add_theme_stylebox_override("panel", create_preview_stylebox())
	preview_container.add_child(background_panel)
	
	# Create SubViewport for shared character preview
	shared_viewport = SubViewport.new()
	shared_viewport.name = "SharedCharacterViewport"
	shared_viewport.size = Vector2i(800, 300)
	shared_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	shared_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	shared_viewport.transparent_bg = true
	
	# Create camera for the viewport
	shared_camera = Camera2D.new()
	shared_camera.position = Vector2(400, 150)  # Center of viewport
	shared_viewport.add_child(shared_camera)
	
	# Create shared ground
	shared_ground = StaticBody2D.new()
	shared_ground.name = "SharedGround"
	
	# Create collision shape for the ground
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(800, 20)  # Full width of viewport
	collision_shape.shape = shape
	collision_shape.position = Vector2(400, 290)  # Position at bottom of viewport
	shared_ground.add_child(collision_shape)
	
	# Create visual representation of the ground
	var ground_sprite = ColorRect.new()
	ground_sprite.color = Color(0.4, 0.4, 0.5, 1.0)
	ground_sprite.size = Vector2(800, 20)
	ground_sprite.position = Vector2(0, 280)  # Position at bottom
	shared_ground.add_child(ground_sprite)
	
	# Add a subtle top border
	var ground_border = ColorRect.new()
	ground_border.color = Color(0.6, 0.6, 0.7, 1.0)
	ground_border.size = Vector2(800, 2)
	ground_border.position = Vector2(0, 280)
	shared_ground.add_child(ground_border)
	
	shared_viewport.add_child(shared_ground)
	
	# Create TextureRect to display the viewport
	var texture_rect = TextureRect.new()
	texture_rect.texture = shared_viewport.get_texture()
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	preview_container.add_child(shared_viewport)
	preview_container.add_child(texture_rect)
	
	# Add to main container after title
	main_container.add_child(preview_container)
	main_container.move_child(preview_container, 1)  # After title, before character grid

func create_character_cards():
	# Check if character_grid exists
	if not character_grid:
		print("Error: character_grid is null!")
		return
	
	# Clear existing children
	for child in character_grid.get_children():
		child.queue_free()
	
	character_cards.clear()
	
	# Create character cards
	for i in range(characters.size()):
		var character_data = characters[i]
		var card = create_character_card(character_data, i)
		character_grid.add_child(card)
		character_cards.append(card)

func create_character_card(character_data: Dictionary, index: int) -> Control:
	var card = VBoxContainer.new()
	card.custom_minimum_size = Vector2(180, 200)  # Smaller cards for portraits
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Add some spacing and padding
	card.add_theme_constant_override("separation", 10)
	
	# Add margin container for padding
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 8)
	margin_container.add_theme_constant_override("margin_right", 8)
	margin_container.add_theme_constant_override("margin_top", 8)
	margin_container.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin_container)
	
	# Portrait container
	var portrait_container = Control.new()
	portrait_container.name = "PortraitContainer_" + character_data["name"].replace(" ", "_")
	portrait_container.custom_minimum_size = Vector2(160, 120)  # Square-ish portrait area
	portrait_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Add a background panel for the portrait
	var background_panel = Panel.new()
	background_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_panel.add_theme_stylebox_override("panel", create_portrait_stylebox())
	portrait_container.add_child(background_panel)
	
	# Create a simple portrait using a colored rectangle with character initial
	var portrait = ColorRect.new()
	portrait.color = get_character_portrait_color(character_data["name"])
	portrait.size = Vector2(140, 100)
	portrait.position = Vector2(10, 10)
	portrait_container.add_child(portrait)
	
	# Add character initial/icon
	var initial_label = Label.new()
	initial_label.text = get_character_initial(character_data["name"])
	initial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initial_label.add_theme_font_size_override("font_size", 36)
	initial_label.add_theme_color_override("font_color", Color.WHITE)
	initial_label.size = Vector2(140, 100)
	initial_label.position = Vector2(10, 10)
	portrait_container.add_child(initial_label)
	
	margin_container.add_child(portrait_container)
	
	# Character name
	var name_label = Label.new()
	name_label.text = character_data["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	margin_container.add_child(name_label)
	
	# Character description
	var desc_label = Label.new()
	desc_label.text = character_data["description"]
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	margin_container.add_child(desc_label)
	
	# Select button
	var select_button = Button.new()
	select_button.text = "Select"
	select_button.size = Vector2(100, 15)
	select_button.position = Vector2(0, 100)
	select_button.custom_minimum_size = Vector2(160, 25)  # Smaller button
	select_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	select_button.add_theme_font_size_override("font_size", 12)
	margin_container.add_child(select_button)
	
	# Connect signals
	select_button.pressed.connect(_on_character_selected.bind(character_data["scene_path"]))
	
	# Store references for hover handling
	card.set_meta("character_data", character_data)
	card.set_meta("index", index)
	card.set_meta("is_selected", false)
	
	# Connect hover signals
	card.mouse_entered.connect(_on_card_hover_entered.bind(card))
	card.mouse_exited.connect(_on_card_hover_exited.bind(card))
	
	return card

func get_character_portrait_color(character_name: String) -> Color:
	match character_name:
		"Tung tung tung Sahur":
			return Color(0.8, 0.4, 0.2, 1.0)  # Orange-brown
		"Tralalero Tralala":
			return Color(0.2, 0.6, 0.8, 1.0)  # Blue
		"Cappucino Assasino":
			return Color(0.6, 0.3, 0.1, 1.0)  # Brown
		_:
			return Color(0.5, 0.5, 0.5, 1.0)  # Default gray

func get_character_initial(character_name: String) -> String:
	match character_name:
		"Tung tung tung Sahur":
			return "T"
		"Tralalero Tralala":
			return "T"
		"Cappucino Assasino":
			return "C"
		_:
			return "?"

func create_portrait_stylebox() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.5, 0.7, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	return style

func create_card_stylebox() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.25, 0.9)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.4, 0.4, 0.8, 1.0)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	
	# Add a subtle shadow effect
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 8
	style.shadow_offset = Vector2(2, 2)
	
	return style

func create_preview_stylebox() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.5, 0.5, 0.9, 1.0)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	
	# Add a subtle shadow effect
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 12
	style.shadow_offset = Vector2(3, 3)
	
	return style

func setup_buttons():
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	update_next_button_state()

func _on_character_selected(character_path: String):
	selected_character_path = character_path
	update_next_button_state()
	update_shared_character_preview()
	
	# Visual feedback - highlight selected card
	for i in range(character_cards.size()):
		var card = character_cards[i]
		var is_selected = characters[i]["scene_path"] == character_path
		card.set_meta("is_selected", is_selected)
		
		# Update card appearance
		var margin_container = card.get_child(0)  # Margin container
		var portrait_container = margin_container.get_child(0)  # Portrait container
		var panel = portrait_container.get_child(0)  # Background panel
		var style = panel.get_theme_stylebox("panel")
		if is_selected:
			style.border_color = Color(0.8, 0.8, 1.0, 1.0)
			style.bg_color = Color(0.3, 0.3, 0.5, 0.95)
		else:
			style.border_color = Color(0.5, 0.5, 0.7, 1.0)
			style.bg_color = Color(0.2, 0.2, 0.3, 0.9)

func update_shared_character_preview():
	# Remove existing character instance if any
	if shared_character_instance:
		shared_character_instance.queue_free()
		shared_character_instance = null
	
	# Find the selected character data
	var selected_character_data = null
	for character_data in characters:
		if character_data["scene_path"] == selected_character_path:
			selected_character_data = character_data
			break
	
	if not selected_character_data or not shared_viewport:
		return
	
	# Create new character instance
	shared_character_instance = selected_character_data["preview_scene"].instantiate()
	shared_character_instance.position = Vector2(400, 270)  # Position on the ground
	
	# Setup physics for the character
	shared_character_instance.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	shared_character_instance.velocity = Vector2.ZERO
	shared_character_instance.gravity = 500
	
	# Enable physics processing
	shared_character_instance.set_physics_process(true)
	shared_character_instance.set_process(false)
	
	# Setup collision detection
	if shared_character_instance.has_method("set_collision_layer_value"):
		shared_character_instance.set_collision_layer_value(1, false)
	if shared_character_instance.has_method("set_collision_mask_value"):
		shared_character_instance.set_collision_mask_value(1, true)
	
	# Override run_speed to prevent movement
	if "run_speed" in shared_character_instance:
		shared_character_instance.run_speed = 0.0  # No movement
	
	# Setup animated sprite
	var animated_sprite = shared_character_instance.get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.visible = true
		animated_sprite.modulate = Color.WHITE
		animated_sprite.play("run")
	
	# Add to shared viewport
	shared_viewport.add_child(shared_character_instance)
	
	# Start running animation cycle
	start_shared_character_animation()

func start_shared_character_animation():
	if not shared_character_instance:
		return
	
	# Create a timer for character movement
	var movement_timer = Timer.new()
	shared_character_instance.add_child(movement_timer)
	movement_timer.wait_time = 0.1  # Update movement frequently
	movement_timer.one_shot = false
	movement_timer.timeout.connect(_on_shared_character_movement_timeout)
	movement_timer.start()
	
	# Store timer reference
	shared_character_instance.set_meta("movement_timer", movement_timer)
	
	# Set initial movement direction
	shared_character_instance.set_meta("moving_right", true)

func _on_shared_character_movement_timeout():
	# Character stays in place - no movement needed
	pass

func _on_card_hover_entered(card: Control):
	hovered_card = card
	# Visual feedback for hover - could add subtle effects here

func _on_card_hover_exited(card: Control):
	if hovered_card == card:
		hovered_card = null



func update_next_button_state():
	if next_button:
		next_button.disabled = selected_character_path.is_empty()

func _on_next_pressed():
	if not selected_character_path.is_empty():
		# Pass the selected character to the next scene
		get_tree().set_meta("selected_character", selected_character_path)
		character_selected.emit(selected_character_path)
		get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn") 
