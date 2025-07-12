extends Control

signal character_selected(character_scene_path: String)

var character_grid: GridContainer
var next_button: Button
var back_button: Button

var selected_character_path: String = ""
var character_cards: Array[Control] = []
var hovered_card: Control = null

# Character data
var characters = [
	{
		"name": "Classic Runner",
		"description": "Simple animations\nPerfect for beginners",
		"scene_path": "res://Player/tung.tscn",
		"preview_scene": preload("res://Player/tung.tscn")
	},
	{
		"name": "Space Marine", 
		"description": "Rich animations with gun variants\nFor experienced players",
		"scene_path": "res://Player/space-marine.tscn",
		"preview_scene": preload("res://Player/space-marine.tscn")
	}
]

func _ready():
	setup_character_grid()
	setup_buttons()
	
	# Start with first character selected
	if characters.size() > 0:
		selected_character_path = characters[0]["scene_path"]
		update_next_button_state()
		update_character_animations()
	
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
	for i in range(character_cards.size()):
		var card = character_cards[i]
		var character_instance = card.get_meta("character_instance", null)
		var character_data = card.get_meta("character_data", {})
		var character_name = character_data.get("name", "Unknown")
		
		if character_instance:
			var character_position = character_instance.position
			var card_position = card.global_position
			var card_size = card.size
			var character_global_position = character_instance.global_position
			
			# Get the viewport that contains the character
			var viewport = character_instance.get_parent()
			var viewport_size = Vector2(viewport.size) if viewport else Vector2.ZERO
			
			# Get the preview container (parent of viewport) for position
			var preview_container = viewport.get_parent() if viewport else null
			var viewport_position = preview_container.global_position if preview_container else Vector2.ZERO
			
			print("Character: ", character_name)
			print("  Character Local Position: ", character_position)
			print("  Character Global Position: ", character_global_position)
			print("  Viewport Global Position: ", viewport_position)
			print("  Viewport Size: ", viewport_size)
			print("  Card Global Position: ", card_position)
			print("  Card Size: ", card_size)
			print("  Is Selected: ", card.get_meta("is_selected", false))
			
			# Calculate the center of the card
			var card_center = card_position + card_size / 2
			print("  Card Center: ", card_center)
			
			# Calculate the center of the viewport
			var viewport_center = viewport_position + viewport_size / 2
			print("  Viewport Center: ", viewport_center)
			
			# Calculate offset from card center
			var offset_from_center = character_global_position - card_center
			print("  Offset from Card Center: ", offset_from_center)
			
			# Calculate offset from viewport center
			var offset_from_viewport_center = character_position - viewport_size / 2
			print("  Offset from Viewport Center: ", offset_from_viewport_center)
			
			# Debug visibility info
			print("  Character Visible: ", character_instance.visible)
			print("  Character Modulate: ", character_instance.modulate)
			
			# Get animated sprite size and frame info
			var animated_sprite = character_instance.get_node_or_null("AnimatedSprite2D")
			if animated_sprite:
				print("  AnimatedSprite Frame: ", animated_sprite.frame)
				print("  AnimatedSprite Animation: ", animated_sprite.animation)
				print("  AnimatedSprite Visible: ", animated_sprite.visible)
				print("  AnimatedSprite SpriteFrames: ", "Has frames" if animated_sprite.sprite_frames else "No frames")
			else:
				print("  AnimatedSprite: Not found")
				
			print("  Viewport Children Count: ", viewport.get_child_count() if viewport else 0)
		else:
			print("Character: ", character_name, " - Instance not found!")
	print("==============================")

func setup_character_grid():
	# Create the character grid since it's missing from the scene
	var main_container = $MainContainer
	if not main_container:
		print("Error: MainContainer not found!")
		return
	
	# Create the character grid
	character_grid = GridContainer.new()
	character_grid.columns = 2
	character_grid.add_theme_constant_override("h_separation", 40)
	character_grid.add_theme_constant_override("v_separation", 40)
	character_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Add it to the main container after the title
	main_container.add_child(character_grid)
	main_container.move_child(character_grid, 1)  # Move it after the title
	
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
	card.custom_minimum_size = Vector2(220, 280)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Add some spacing and padding
	card.add_theme_constant_override("separation", 15)
	
	# Add margin container for padding
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 10)
	margin_container.add_theme_constant_override("margin_right", 10)
	margin_container.add_theme_constant_override("margin_top", 10)
	margin_container.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin_container)
	
	# Character preview container
	var preview_container = Control.new()
	preview_container.name = "PreviewContainer_" + character_data["name"].replace(" ", "_")
	preview_container.custom_minimum_size = Vector2(200, 120)  # Reduced height to better align with button
	preview_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Add a background panel as a child
	var background_panel = Panel.new()
	background_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_panel.add_theme_stylebox_override("panel", create_card_stylebox())
	preview_container.add_child(background_panel)
	
	# SubViewport for character preview
	var viewport = SubViewport.new()
	viewport.name = "Viewport_" + character_data["name"].replace(" ", "_")
	viewport.size = Vector2i(200, 120)  # Match container size
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE  # Only update when visible
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS  # Always clear
	viewport.transparent_bg = true  # Enable transparent background
	
	# Camera for the viewport
	var camera = Camera2D.new()
	camera.position = Vector2(100, 60)  # Center camera to match character position
	viewport.add_child(camera)
	
	# No ground needed since we're disabling physics for preview
	
	# Character instance - use the actual player scene
	var character_instance = character_data["preview_scene"].instantiate()
	character_instance.position = Vector2(100, 60)  # Center in viewport (viewport is 200x120)
	
	# Debug: Print character node structure
	print("Character instance created for ", character_data["name"])
	print("  Character children count: ", character_instance.get_child_count())
	for i in range(character_instance.get_child_count()):
		var child = character_instance.get_child(i)
		print("  Child ", i, ": ", child.name, " (", child.get_class(), ")")
	
	# Completely disable physics for preview
	character_instance.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	character_instance.velocity = Vector2.ZERO
	character_instance.gravity = 0
	
	# Disable all physics processing
	character_instance.set_physics_process(false)
	character_instance.set_process(false)
	
	# Disable collision detection for preview
	if character_instance.has_method("set_collision_layer_value"):
		character_instance.set_collision_layer_value(1, false)
	if character_instance.has_method("set_collision_mask_value"):
		character_instance.set_collision_mask_value(1, false)
	
	# Override the run_speed to prevent movement
	if "run_speed" in character_instance:
		character_instance.run_speed = 0.0
	
	# No need for velocity reset timer since physics are disabled
	
	# Ensure the character's AnimatedSprite2D is visible and playing idle
	var animated_sprite = character_instance.get_node_or_null("AnimatedSprite2D")
	if animated_sprite:		
		# Make sure the sprite is visible and properly connected
		animated_sprite.visible = true
		animated_sprite.modulate = Color.WHITE
		animated_sprite.play("run")
	else:
		print("WARNING: AnimatedSprite2D not found for ", character_data["name"])
	
	# Add to viewport
	viewport.add_child(character_instance)
	
	# Check if the character instance is properly connected
	var character_parent = character_instance.get_parent()
	print("Character instance parent for ", character_data["name"], ": ", character_parent.name if character_parent else "NULL")
	
	# If the character is orphaned, re-add it to the viewport
	if not character_parent or character_parent != viewport:
		print("Fixing orphaned character instance for ", character_data["name"])
		if character_parent:
			character_parent.remove_child(character_instance)
		viewport.add_child(character_instance)
	
	# Ensure the character is visible and properly connected
	character_instance.visible = true
	character_instance.modulate = Color.WHITE
	
	print("Added character to viewport: ", character_data["name"], " - Viewport children: ", viewport.get_child_count())
	
	# Verify the final connection
	var final_character_parent = character_instance.get_parent()
	print("Final character instance parent for ", character_data["name"], ": ", final_character_parent.name if final_character_parent else "NULL")
	
	# Create TextureRect to display the viewport
	var texture_rect = TextureRect.new()
	texture_rect.texture = viewport.get_texture()
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Add viewport to preview container
	preview_container.add_child(viewport)
	preview_container.add_child(texture_rect)
	
	# Check viewport parent connection
	var viewport_parent = viewport.get_parent()
	print("Viewport parent for ", character_data["name"], ": ", viewport_parent.name if viewport_parent else "NULL")
	
	# Ensure preview container is visible and properly sized
	preview_container.visible = true
	preview_container.modulate = Color.WHITE
	
	margin_container.add_child(preview_container)
	
	# Debug preview container info
	print("Preview container for ", character_data["name"], ":")
	print("  Name: ", preview_container.name)
	print("  Visible: ", preview_container.visible)
	print("  Size: ", preview_container.size)
	print("  Custom min size: ", preview_container.custom_minimum_size)
	
	# Force size update
	preview_container.size = Vector2(200, 120)
	print("  Forced size to: ", preview_container.size)
	
	# Defer size update to ensure proper layout
	preview_container.call_deferred("set_size", Vector2(200, 120))
	
	# Character name
	var name_label = Label.new()
	name_label.text = character_data["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	margin_container.add_child(name_label)
	
	# Character description
	var desc_label = Label.new()
	desc_label.text = character_data["description"]
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	margin_container.add_child(desc_label)
	
	# Select button
	var select_button = Button.new()
	select_button.text = "Select"
	select_button.size = Vector2(100, 15)
	select_button.custom_minimum_size = Vector2(200, 20)  # Half the default button height
	select_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	select_button.add_theme_font_size_override("font_size", 12)  # Smaller font to fit
	margin_container.add_child(select_button)
	
	# Connect signals
	select_button.pressed.connect(_on_character_selected.bind(character_data["scene_path"]))
	
	# Store references for hover handling
	card.set_meta("character_instance", character_instance)
	card.set_meta("character_data", character_data)
	card.set_meta("index", index)
	card.set_meta("is_selected", false)
	
	# Connect hover signals
	card.mouse_entered.connect(_on_card_hover_entered.bind(card))
	card.mouse_exited.connect(_on_card_hover_exited.bind(card))
	
	return card

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

func setup_buttons():
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	update_next_button_state()

func _on_character_selected(character_path: String):
	selected_character_path = character_path
	update_next_button_state()
	update_character_animations()
	
	# Visual feedback - highlight selected card
	for i in range(character_cards.size()):
		var card = character_cards[i]
		var is_selected = characters[i]["scene_path"] == character_path
		card.set_meta("is_selected", is_selected)
		
		# Update card appearance
		var margin_container = card.get_child(0)  # Margin container
		var panel = margin_container.get_child(0)  # Preview container
		var style = panel.get_theme_stylebox("panel")
		if is_selected:
			style.border_color = Color(0.8, 0.8, 1.0, 1.0)
			style.bg_color = Color(0.3, 0.3, 0.5, 0.95)
			style.shadow_color = Color(0.8, 0.8, 1.0, 0.4)
		else:
			style.border_color = Color(0.4, 0.4, 0.8, 1.0)
			style.bg_color = Color(0.15, 0.15, 0.25, 0.9)
			style.shadow_color = Color(0, 0, 0, 0.3)

func update_character_animations():
	# Update animations for all characters based on selection
	for i in range(character_cards.size()):
		var card = character_cards[i]
		var character_instance = card.get_meta("character_instance")
		var is_selected = characters[i]["scene_path"] == selected_character_path
		
		if character_instance and character_instance.has_node("AnimatedSprite2D"):
			var animated_sprite = character_instance.get_node("AnimatedSprite2D")
			
			if is_selected:
				# Start random animation cycle for selected character
				start_random_animation_cycle(character_instance)
			else:
				# Stop animations and return to idle for non-selected characters
				stop_animation_cycle(character_instance)
				animated_sprite.play("idle")

func _on_card_hover_entered(card: Control):
	hovered_card = card
	# Only start animations on hover if this character is selected
	var is_selected = card.get_meta("is_selected", false)
	if is_selected:
		var character_instance = card.get_meta("character_instance")
		start_random_animation_cycle(character_instance)

func _on_card_hover_exited(card: Control):
	if hovered_card == card:
		hovered_card = null
		# Only stop animations if this character is not selected
		var is_selected = card.get_meta("is_selected", false)
		if not is_selected:
			var character_instance = card.get_meta("character_instance")
			stop_animation_cycle(character_instance)

func start_random_animation_cycle(character_instance: Node):
	if not character_instance or not character_instance.has_node("AnimatedSprite2D"):
		return
	
	# Don't start a new timer if one already exists
	if character_instance.has_meta("animation_timer"):
		return
	
	# Create a timer for random animation changes
	var animation_timer = Timer.new()
	character_instance.add_child(animation_timer)
	animation_timer.wait_time = 3.0  # Change animation every 3 seconds
	animation_timer.one_shot = false
	animation_timer.timeout.connect(_on_animation_timer_timeout.bind(character_instance))
	animation_timer.start()
	
	# Store timer reference
	character_instance.set_meta("animation_timer", animation_timer)
	
	# Start with a random animation
	play_random_animation(character_instance)

func stop_animation_cycle(character_instance: Node):
	if not character_instance:
		return
	
	# Stop and remove timer
	var timer = character_instance.get_meta("animation_timer", null)
	if timer:
		timer.stop()
		timer.queue_free()
		character_instance.set_meta("animation_timer", null)
	
	# Return to idle animation
	var animated_sprite = character_instance.get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.play("idle")

func _on_animation_timer_timeout(character_instance: Node):
	play_random_animation(character_instance)

func play_random_animation(character_instance: Node):
	if not character_instance:
		return
	
	# Get the animated sprite directly
	var animated_sprite = character_instance.get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		return
	
	# Get available animations from the sprite frames
	var sprite_frames = animated_sprite.sprite_frames
	if not sprite_frames:
		return
	
	var available_animations = sprite_frames.get_animation_names()
	
	# Filter to only include appropriate preview animations
	var preview_animations = []
	for anim_name in available_animations:
		if anim_name in ["idle", "run", "shoot", "jump", "crouch", "idle_gun", "run_gun", "jump_gun", "crouch_gun"]:
			preview_animations.append(anim_name)
	
	# If no preview animations found, use all available
	if preview_animations.is_empty():
		preview_animations = available_animations
	
	# Play a random animation
	var random_animation = preview_animations[randi() % preview_animations.size()]
	animated_sprite.play(random_animation)

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
