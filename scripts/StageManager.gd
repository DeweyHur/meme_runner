extends Node

# Stage definitions
var stages = [
	{
		"name": "Jungle Stage",
		"scene_path": "res://scenes/stages/JungleStage.tscn",
		"description": "A dense jungle filled with ancient ruins and dangerous wildlife",
		"difficulty": 1.0
	},
	{
		"name": "Cyberpunk Stage", 
		"scene_path": "res://scenes/stages/CyberpunkStage.tscn",
		"description": "A neon-lit cityscape with towering skyscrapers and flying cars",
		"difficulty": 1.2
	},
	{
		"name": "Volcano Stage",
		"scene_path": "res://scenes/stages/VolcanoStage.tscn", 
		"description": "A treacherous volcanic landscape with flowing lava and ash clouds",
		"difficulty": 1.5
	}
]

var current_stage_index: int = 0
var current_stage_instance: Node2D = null

signal stage_changed(stage_data: Dictionary)
signal stage_completed(stage_number: int)

func _ready():
	# Initialize with first stage
	load_stage(0)

func get_current_stage() -> Node2D:
	return current_stage_instance

func get_current_stage_data() -> Dictionary:
	if current_stage_index >= 0 and current_stage_index < stages.size():
		return stages[current_stage_index]
	return {}

func get_total_stages() -> int:
	return stages.size()

func get_current_stage_number() -> int:
	return current_stage_index + 1

func load_stage(stage_index: int):
	if stage_index < 0 or stage_index >= stages.size():
		print("Invalid stage index: ", stage_index)
		return
	
	# Clean up current stage if it exists
	if current_stage_instance:
		current_stage_instance.cleanup_stage()
		current_stage_instance.queue_free()
	
	# Load new stage
	var stage_data = stages[stage_index]
	var stage_scene = load(stage_data["scene_path"])
	
	if stage_scene:
		current_stage_instance = stage_scene.instantiate()
		current_stage_index = stage_index
		
		# Add stage to the scene tree
		get_parent().add_child(current_stage_instance)
		
		# Connect stage completion signal
		if current_stage_instance.has_signal("stage_completed_signal"):
			current_stage_instance.stage_completed_signal.connect(_on_stage_completed)
		
		print("Loaded stage: ", stage_data["name"])
		stage_changed.emit(stage_data)
	else:
		print("Failed to load stage scene: ", stage_data["scene_path"])

func next_stage():
	if current_stage_index < stages.size() - 1:
		load_stage(current_stage_index + 1)
		return true
	else:
		print("No more stages available")
		return false

func restart_current_stage():
	load_stage(current_stage_index)

func _on_stage_completed():
	stage_completed.emit(current_stage_index + 1)
	print("Stage %d completed!" % (current_stage_index + 1))

func get_stage_name(stage_number: int) -> String:
	if stage_number > 0 and stage_number <= stages.size():
		return stages[stage_number - 1]["name"]
	return "Unknown Stage"

func get_stage_description(stage_number: int) -> String:
	if stage_number > 0 and stage_number <= stages.size():
		return stages[stage_number - 1]["description"]
	return "Unknown stage description" 
