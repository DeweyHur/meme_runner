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
	
	# Create a bottom container for the buttons
	var bottom_container = HBoxContainer.new()
	bottom_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.add_child(bottom_container)
	
	# Create new buttons instead of moving existing ones
	self.back_button = Button.new()
	self.back_button.text = "Back to Menu"
	self.back_button.custom_minimum_size = Vector2(120, 40)
	self.back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	self.back_button.add_theme_font_size_override("font_size", 16)
	bottom_container.add_child(self.back_button)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_container.add_child(spacer)
	
	self.next_button = Button.new()
	self.next_button.text = "Next"
	self.next_button.custom_minimum_size = Vector2(120, 40)
	self.next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	self.next_button.add_theme_font_size_override("font_size", 16)
	bottom_container.add_child(self.next_button)
	
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
	var preview_container = Panel.new()
	preview_container.custom_minimum_size = Vector2(200, 160)
	preview_container.add_theme_stylebox_override("panel", create_card_stylebox())
	
	# SubViewport for character preview
	var viewport = SubViewport.new()
	viewport.size = Vector2i(200, 160)
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	
	# Camera for the viewport
	var camera = Camera2D.new()
	camera.position = Vector2(0, -20)
	viewport.add_child(camera)
	
	# Ground for the character
	var ground = StaticBody2D.new()
	var ground_collision = CollisionShape2D.new()
	var ground_shape = RectangleShape2D.new()
	ground_shape.size = Vector2(200, 20)
	ground_collision.shape = ground_shape
	ground_collision.position = Vector2(0, 60)
	ground.add_child(ground_collision)
	viewport.add_child(ground)
	
	# Character instance
	var character_instance = character_data["preview_scene"].instantiate()
	character_instance.position = Vector2(0, 0)
	character_instance.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	character_instance.velocity = Vector2.ZERO
	
	# Disable physics processing for preview
	character_instance.set_physics_process(false)
	character_instance.set_process(false)
	
	# Add to viewport
	viewport.add_child(character_instance)
	
	# Add viewport to preview container
	preview_container.add_child(viewport)
	margin_container.add_child(preview_container)
	
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
	select_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	select_button.add_theme_font_size_override("font_size", 14)
	margin_container.add_child(select_button)
	
	# Connect signals
	select_button.pressed.connect(_on_character_selected.bind(character_data["scene_path"]))
	
	# Store references for hover handling
	card.set_meta("character_instance", character_instance)
	card.set_meta("character_data", character_data)
	card.set_meta("index", index)
	
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
	
	# Visual feedback - highlight selected card
	for i in range(character_cards.size()):
		var card = character_cards[i]
		var is_selected = characters[i]["scene_path"] == character_path
		
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

func _on_card_hover_entered(card: Control):
	hovered_card = card
	var character_instance = card.get_meta("character_instance")
	
	# Start random animation cycle
	start_random_animation_cycle(character_instance)

func _on_card_hover_exited(card: Control):
	if hovered_card == card:
		hovered_card = null
		var character_instance = card.get_meta("character_instance")
		
		# Stop animations and return to idle
		stop_animation_cycle(character_instance)

func start_random_animation_cycle(character_instance: Node):
	if not character_instance or not character_instance.has_method("update_animations"):
		return
	
	# Create a timer for random animation changes
	var animation_timer = Timer.new()
	character_instance.add_child(animation_timer)
	animation_timer.wait_time = 2.0  # Change animation every 2 seconds
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
	
	# Available animations: run, shoot, jump, crouch
	var animations = ["run", "shoot", "jump", "crouch"]
	var random_animation = animations[randi() % animations.size()]
	
	# Play the animation directly
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
