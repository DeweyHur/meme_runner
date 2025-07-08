extends StaticBody2D

var left_height: float
var right_height: float

func get_ground_height() -> float:
	# Return the average height of the ground piece
	return (left_height + right_height) / 2.0

func get_ground_height_at_x(x_offset: float) -> float:
	# Return the height at a specific x offset within this ground piece
	# x_offset should be between -segment_width/2 and segment_width/2
	var segment_width = 200.0  # This should match the segment_width from ProceduralGround
	var normalized_x = (x_offset + segment_width/2) / segment_width
	return lerp(left_height, right_height, normalized_x)

func get_ground_info_at_x(x_offset: float) -> Dictionary:
	# Return both height and normal at a specific x offset within this ground piece
	var height = get_ground_height_at_x(x_offset)
	
	# Calculate the normal based on the slope
	var segment_width = 200.0  # This should match the segment_width from ProceduralGround
	var height_diff = right_height - left_height
	
	# Calculate slope direction (tangent vector)
	var tangent = Vector2(segment_width, height_diff).normalized()
	
	# Calculate normal (perpendicular to tangent, pointing upward)
	var normal = Vector2(-tangent.y, tangent.x)
	
	# Ensure normal points upward (away from ground)
	if normal.y < 0:
		normal = -normal
	
	return {
		"height": height,
		"normal": normal
	} 