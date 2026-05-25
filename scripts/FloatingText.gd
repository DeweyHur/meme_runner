extends Node2D

var elapsed = 0.0
var lifetime = 1.3
var float_speed = -65.0

func setup(text: String, color: Color = Color.WHITE, size: int = 22):
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-60, 0)
	lbl.custom_minimum_size = Vector2(120, 40)
	add_child(lbl)

func _process(delta):
	elapsed += delta
	position.y += float_speed * delta
	modulate.a = clamp(1.0 - (elapsed / lifetime) * 1.5, 0.0, 1.0)
	if elapsed >= lifetime:
		queue_free()
