extends Area2D

var player: Node2D = null
var speed = 0.0
var max_speed = 160.0
var spawn_y = 0.0
var charge_timer = 0.0
var is_charging = false
var body_rect: ColorRect = null
var fuse_spark: ColorRect = null
var warn_label: Label = null

func _ready():
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	player = get_tree().get_first_node_in_group("player")
	spawn_y = position.y

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 22.0
	col.shape = shape
	col.position = Vector2(0, -22)
	add_child(col)

	# Shadow
	var shadow = ColorRect.new()
	shadow.size = Vector2(44, 8)
	shadow.position = Vector2(-22, -4)
	shadow.color = Color(0, 0, 0, 0.3)
	add_child(shadow)

	# Bomb body (dark outline)
	var outline = ColorRect.new()
	outline.size = Vector2(48, 48)
	outline.position = Vector2(-24, -48)
	outline.color = Color(0.0, 0.0, 0.0)
	add_child(outline)

	# Bomb body (main)
	body_rect = ColorRect.new()
	body_rect.size = Vector2(44, 44)
	body_rect.position = Vector2(-22, -46)
	body_rect.color = Color(1.0, 0.55, 0.0)
	add_child(body_rect)

	# Shine on bomb
	var shine = ColorRect.new()
	shine.size = Vector2(12, 12)
	shine.position = Vector2(-18, -44)
	shine.color = Color(1.0, 0.9, 0.6, 0.6)
	add_child(shine)

	# Bomb face - eyes
	for i in 2:
		var eye = ColorRect.new()
		eye.size = Vector2(8, 8)
		eye.position = Vector2(-12 + i * 16, -34)
		eye.color = Color(0.05, 0.05, 0.05)
		add_child(eye)

	# Bomb face - angry mouth
	var mouth = ColorRect.new()
	mouth.size = Vector2(20, 4)
	mouth.position = Vector2(-10, -22)
	mouth.color = Color(0.05, 0.05, 0.05)
	add_child(mouth)

	# Fuse (stick on top)
	var fuse = ColorRect.new()
	fuse.size = Vector2(5, 18)
	fuse.position = Vector2(-2, -64)
	fuse.color = Color(0.45, 0.3, 0.1)
	add_child(fuse)

	# Fuse spark
	fuse_spark = ColorRect.new()
	fuse_spark.size = Vector2(9, 9)
	fuse_spark.position = Vector2(-4, -74)
	fuse_spark.color = Color(1.0, 1.0, 0.2)
	add_child(fuse_spark)

	# "BOMB" tag
	var tag_bg = ColorRect.new()
	tag_bg.size = Vector2(56, 20)
	tag_bg.position = Vector2(-28, -96)
	tag_bg.color = Color(0.9, 0.4, 0.0)
	add_child(tag_bg)
	warn_label = Label.new()
	warn_label.text = "BOMB!"
	warn_label.add_theme_font_size_override("font_size", 13)
	warn_label.add_theme_color_override("font_color", Color.WHITE)
	warn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn_label.position = Vector2(-28, -97)
	warn_label.custom_minimum_size = Vector2(56, 20)
	add_child(warn_label)

	# Wind-up before charging
	var wind_up = Timer.new()
	add_child(wind_up)
	wind_up.wait_time = 1.2
	wind_up.one_shot = true
	wind_up.timeout.connect(func():
		is_charging = true
		if body_rect:
			body_rect.color = Color(1.0, 0.2, 0.0)
		if warn_label:
			warn_label.text = "RUN!!!"
	)
	wind_up.start()

	var cleanup = Timer.new()
	add_child(cleanup)
	cleanup.wait_time = 16.0
	cleanup.one_shot = true
	cleanup.timeout.connect(queue_free)
	cleanup.start()

func _physics_process(delta):
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	charge_timer += delta

	# Fuse spark blink
	if fuse_spark:
		fuse_spark.visible = int(charge_timer * 8) % 2 == 0
		var spark_colors = [Color(1.0, 1.0, 0.2), Color(1.0, 0.6, 0.1), Color(1.0, 0.2, 0.0)]
		fuse_spark.color = spark_colors[int(charge_timer * 6) % 3]

	if not is_charging:
		# Pulse while winding up
		var pulse = 1.0 + sin(charge_timer * 5.0) * 0.08
		scale = Vector2(pulse, pulse)
		return

	speed = min(max_speed, speed + 60.0 * delta)
	var dir = sign(player.global_position.x - global_position.x)
	position.x += dir * speed * delta
	position.y = spawn_y

	# Fast pulse when charging
	var pulse = 1.0 + sin(charge_timer * 12.0) * 0.1
	scale = Vector2(pulse, pulse)

func explode():
	var game = get_tree().get_first_node_in_group("game_node")
	if game:
		if game.has_method("enemy_killed"):
			game.enemy_killed("bomber", global_position)
		if game.has_method("camera_shake"):
			game.camera_shake(0.45)

	var expl_scene = load("res://VFX/explosion.tscn")
	if expl_scene:
		for i in 3:
			var e = expl_scene.instantiate()
			get_parent().add_child(e)
			e.global_position = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
			e.scale = Vector2(1.4, 1.4)

	queue_free()

func take_damage():
	explode()

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage") and not body.is_hurt:
		body.take_damage(6.0)
		explode()

func _on_area_entered(area):
	if area.is_in_group("bullets") and area.get("bullet_type") == "player":
		explode()
