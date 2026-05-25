extends CharacterBody2D

const SPEED = 170.0
const JUMP_VELOCITY = -650.0
const NORMAL_SHOOT_INTERVAL = 4.0
const RAPID_SHOOT_INTERVAL = 0.6
const BOOST_DURATION = 10.0
const RAPID_FIRE_DURATION = 8.0

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var shot_cooldown_indicator = $ShotCooldownIndicator

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var run_speed = SPEED
var speed_multiplier = 1.0

var is_jumping = false
var jump_count = 0
var max_jumps = 2

var is_sliding = false
var is_crouching = false
var is_shooting = false
var is_hurt = false
var hurt_velocity = Vector2.ZERO
var hurt_timer = 0.0

var debug_info = {}
var max_walkable_slope_angle = 25.0
var slope_movement_enabled = true
var current_slope_angle = 0.0
var slope_normal = Vector2.UP
var debug_slope_info = false

var shoot_timer = 0.0

# Powerup states
var shield_count = 0
var speed_boost_timer = 0.0
var rapid_fire_timer = 0.0

func _ready():
	add_to_group("player")
	var area2d = $Area2D
	if area2d:
		area2d.body_entered.connect(_on_area_body_entered)
		area2d.area_entered.connect(_on_area_area_entered)

func _physics_process(delta):
	if is_hurt:
		hurt_timer += delta
		var deceleration = 400.0
		hurt_velocity.x = move_toward(hurt_velocity.x, 0, deceleration * delta)
		velocity = hurt_velocity
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		update_animations(0)
		return

	_update_powerup_timers(delta)

	if is_on_floor():
		detect_slope_info()
		jump_count = 0
		if is_jumping:
			is_jumping = false
	else:
		current_slope_angle = 0.0
		slope_normal = Vector2.UP

	if is_on_floor() and slope_movement_enabled:
		handle_slope_movement(delta)
	else:
		if not is_on_floor():
			velocity.y += gravity * delta

	# Jump (supports double jump)
	if Input.is_action_just_pressed("ui_accept") and jump_count < max_jumps:
		velocity.y = JUMP_VELOCITY
		jump_count += 1
		is_jumping = true

	# Back jump
	if Input.is_action_just_pressed("ui_left") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		velocity.x = -run_speed * 0.5
		is_jumping = true
		jump_count = 1

	# Crouch
	if Input.is_action_pressed("ui_down") and is_on_floor() and not is_jumping:
		if not is_crouching:
			is_crouching = true
			is_sliding = true
			collision_shape.shape.size.y = 22
			collision_shape.position.y = -11
	else:
		if is_crouching:
			is_crouching = false
			is_sliding = false
			collision_shape.shape.size.y = 43
			collision_shape.position.y = -21.5

	# Auto-shoot
	var current_interval = RAPID_SHOOT_INTERVAL if rapid_fire_timer > 0 else NORMAL_SHOOT_INTERVAL
	shoot_timer += delta
	if shoot_timer >= current_interval:
		shoot()
		shoot_timer = 0.0

	# Manual shoot (Z key)
	if Input.is_action_just_pressed("shoot"):
		shoot()
		shoot_timer = 0.0

	var effective_speed = run_speed * speed_multiplier
	if not is_jumping or velocity.x >= 0:
		velocity.x = effective_speed

	move_and_slide()
	update_animations(1)
	check_collisions()
	update_shot_cooldown_indicator()
	update_powerup_visual()

func _update_powerup_timers(delta):
	if speed_boost_timer > 0:
		speed_boost_timer -= delta
		if speed_boost_timer <= 0:
			speed_boost_timer = 0.0
			speed_multiplier = 1.0
		else:
			speed_multiplier = 1.5
	else:
		speed_multiplier = 1.0

	if rapid_fire_timer > 0:
		rapid_fire_timer -= delta
		if rapid_fire_timer <= 0:
			rapid_fire_timer = 0.0

func activate_shield():
	shield_count = min(shield_count + 1, 3)

func activate_speed_boost():
	speed_boost_timer = BOOST_DURATION

func activate_rapid_fire():
	rapid_fire_timer = RAPID_FIRE_DURATION

func update_powerup_visual():
	if not animated_sprite_2d:
		return
	var base_color: Color
	if shield_count > 0:
		base_color = Color(0.3, 0.6, 1.0, 1.0)
	elif speed_boost_timer > 0:
		base_color = Color(1.0, 1.0, 0.3, 1.0)
	elif rapid_fire_timer > 0:
		base_color = Color(1.0, 0.55, 0.1, 1.0)
	else:
		base_color = Color.WHITE

	if is_hurt:
		base_color.a = 0.25 + 0.75 * abs(sin(hurt_timer * 18.0))

	animated_sprite_2d.modulate = base_color

func detect_slope_info():
	var ground_info = get_ground_info_at_position()
	if ground_info.has("normal"):
		slope_normal = ground_info.normal
		var slope_radians = acos(slope_normal.y)
		current_slope_angle = rad_to_deg(slope_radians)
		if slope_normal.x > 0:
			current_slope_angle = -current_slope_angle
	else:
		current_slope_angle = 0.0
		slope_normal = Vector2.UP

func get_ground_info_at_position() -> Dictionary:
	var game_scene = get_parent()
	if game_scene and game_scene.has_method("get_ground_info_at_position"):
		return game_scene.get_ground_info_at_position(position.x)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.has_method("get_ground_info_at_x"):
			var local_pos = collider.to_local(position)
			return collider.get_ground_info_at_x(local_pos.x)
	return {"height": position.y, "normal": Vector2.UP}

func handle_slope_movement(delta):
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += gravity * delta
	if velocity.y > 0:
		var ground_info = get_ground_info_at_position()
		if ground_info.has("height"):
			if position.y + velocity.y * delta > ground_info.height:
				velocity.y = 0
				position.y = ground_info.height

func get_current_slope_angle() -> float:
	return current_slope_angle

func get_slope_normal() -> Vector2:
	return slope_normal

func is_slope_movement_enabled() -> bool:
	return slope_movement_enabled

func update_shot_cooldown_indicator():
	if not shot_cooldown_indicator:
		return
	var current_interval = RAPID_SHOOT_INTERVAL if rapid_fire_timer > 0 else NORMAL_SHOOT_INTERVAL
	var progress = clamp(shoot_timer / current_interval, 0.0, 1.0)
	shot_cooldown_indicator.value = progress * 100
	if progress >= 1.0:
		shot_cooldown_indicator.modulate = Color(0, 1, 0, 0.8)
	elif progress >= 0.7:
		shot_cooldown_indicator.modulate = Color(1, 1, 0, 0.8)
	else:
		shot_cooldown_indicator.modulate = Color(1, 0, 0, 0.8)

func update_animations(input_axis):
	if input_axis > 0:
		animated_sprite_2d.flip_h = false
	elif input_axis < 0:
		animated_sprite_2d.flip_h = true

	if is_hurt:
		animated_sprite_2d.play("hurt")
	elif is_on_floor():
		if is_crouching:
			animated_sprite_2d.play("crouch")
		elif is_shooting:
			animated_sprite_2d.play("shoot")
		elif input_axis != 0:
			animated_sprite_2d.play("run")
		else:
			animated_sprite_2d.play("idle")
	else:
		if velocity.y > 0:
			animated_sprite_2d.play("fall")
		else:
			animated_sprite_2d.play("jump")

func check_collisions():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("obstacles") and not is_hurt:
			take_damage(20.0)

func game_over():
	velocity = Vector2.ZERO
	var game_scene = get_parent()
	if game_scene.has_method("game_over"):
		game_scene.game_over()

func shoot():
	if not is_shooting:
		is_shooting = true
		var bullet_scene = preload("res://VFX/shot.tscn")
		var bullet = bullet_scene.instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = global_position + Vector2(50, -20)
		bullet.speed = run_speed + 500
		bullet.direction = Vector2.RIGHT
		bullet.bullet_type = "player"
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 0.3
		timer.one_shot = true
		timer.timeout.connect(func(): is_shooting = false)
		timer.start()

func take_damage(amount: float = 3.0):
	if shield_count > 0:
		shield_count -= 1
		# Flash white on shield absorb
		if animated_sprite_2d:
			animated_sprite_2d.modulate = Color.WHITE
		return

	is_hurt = true
	hurt_timer = 0.0
	hurt_velocity = Vector2(-300, 0)

	var game_scene = get_parent()
	if game_scene.has_method("player_took_damage"):
		game_scene.player_took_damage(amount)

	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(func():
		is_hurt = false
		hurt_velocity = Vector2.ZERO
		hurt_timer = 0.0
	)
	timer.start()

func _on_area_body_entered(body):
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		take_damage()
		body.take_damage()

func _on_area_area_entered(area):
	pass
