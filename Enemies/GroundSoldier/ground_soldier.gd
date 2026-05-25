extends Area2D

var player: Node2D = null
var speed = 90.0
var health = 1
var spawn_y = 0.0
var bob_timer = 0.0
var leg_l: ColorRect = null
var leg_r: ColorRect = null

func _ready():
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	player = get_tree().get_first_node_in_group("player")
	spawn_y = position.y

	var col = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.height = 56.0
	shape.radius = 16.0
	col.shape = shape
	col.position = Vector2(0, -28)
	add_child(col)

	# Shadow
	var shadow = ColorRect.new()
	shadow.size = Vector2(38, 8)
	shadow.position = Vector2(-19, -4)
	shadow.color = Color(0, 0, 0, 0.3)
	add_child(shadow)

	# Legs
	leg_l = ColorRect.new()
	leg_l.size = Vector2(14, 22)
	leg_l.position = Vector2(-16, -16)
	leg_l.color = Color(0.15, 0.15, 0.55)
	add_child(leg_l)

	leg_r = ColorRect.new()
	leg_r.size = Vector2(14, 22)
	leg_r.position = Vector2(2, -16)
	leg_r.color = Color(0.15, 0.15, 0.55)
	add_child(leg_r)

	# Torso
	var torso = ColorRect.new()
	torso.size = Vector2(32, 34)
	torso.position = Vector2(-16, -50)
	torso.color = Color(0.85, 0.12, 0.12)
	add_child(torso)

	# Torso highlight
	var torso_hl = ColorRect.new()
	torso_hl.size = Vector2(10, 34)
	torso_hl.position = Vector2(-14, -50)
	torso_hl.color = Color(1.0, 0.3, 0.3, 0.4)
	add_child(torso_hl)

	# Head
	var head = ColorRect.new()
	head.size = Vector2(28, 26)
	head.position = Vector2(-14, -76)
	head.color = Color(0.96, 0.72, 0.52)
	add_child(head)

	# Helmet
	var helmet = ColorRect.new()
	helmet.size = Vector2(30, 12)
	helmet.position = Vector2(-15, -82)
	helmet.color = Color(0.6, 0.1, 0.1)
	add_child(helmet)

	# Eyes
	for i in 2:
		var white_eye = ColorRect.new()
		white_eye.size = Vector2(8, 7)
		white_eye.position = Vector2(-12 + i * 14, -72)
		white_eye.color = Color.WHITE
		add_child(white_eye)
		var pupil = ColorRect.new()
		pupil.size = Vector2(4, 5)
		pupil.position = Vector2(-10 + i * 14, -71)
		pupil.color = Color(0.05, 0.05, 0.8)
		add_child(pupil)

	# Angry brow
	var brow = ColorRect.new()
	brow.size = Vector2(26, 4)
	brow.position = Vector2(-13, -75)
	brow.color = Color(0.3, 0.0, 0.0)
	add_child(brow)

	# "ENEMY" tag above head
	var tag_bg = ColorRect.new()
	tag_bg.size = Vector2(60, 20)
	tag_bg.position = Vector2(-30, -102)
	tag_bg.color = Color(0.9, 0.1, 0.1)
	add_child(tag_bg)
	var tag = Label.new()
	tag.text = "ENEMY"
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", Color.WHITE)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.position = Vector2(-30, -103)
	tag.custom_minimum_size = Vector2(60, 20)
	add_child(tag)

	# HP indicator bar background
	var hp_bg = ColorRect.new()
	hp_bg.size = Vector2(36, 5)
	hp_bg.position = Vector2(-18, -107)
	hp_bg.color = Color(0.2, 0.0, 0.0)
	add_child(hp_bg)
	var hp_bar = ColorRect.new()
	hp_bar.name = "HPBar"
	hp_bar.size = Vector2(36, 5)
	hp_bar.position = Vector2(-18, -107)
	hp_bar.color = Color(0.0, 1.0, 0.2)
	add_child(hp_bar)

	var cleanup = Timer.new()
	add_child(cleanup)
	cleanup.wait_time = 22.0
	cleanup.one_shot = true
	cleanup.timeout.connect(queue_free)
	cleanup.start()

func _physics_process(delta):
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	var dir = sign(player.global_position.x - global_position.x)
	position.x += dir * speed * delta
	position.y = spawn_y

	# Leg bob animation
	bob_timer += delta * speed * 0.06
	if leg_l and leg_r:
		leg_l.position.y = -16 + sin(bob_timer) * 5
		leg_r.position.y = -16 + sin(bob_timer + PI) * 5

	# Face direction of travel
	if dir != 0:
		scale.x = -dir

func take_damage():
	health -= 1
	if health <= 0:
		var game = get_tree().get_first_node_in_group("game_node")
		if game and game.has_method("enemy_killed"):
			game.enemy_killed("soldier", global_position)
		var expl = load("res://VFX/explosion.tscn")
		if expl:
			var e = expl.instantiate()
			get_parent().add_child(e)
			e.global_position = global_position
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage") and not body.is_hurt:
		body.take_damage()
		queue_free()

func _on_area_entered(area):
	if area.is_in_group("bullets") and area.get("bullet_type") == "player":
		take_damage()
