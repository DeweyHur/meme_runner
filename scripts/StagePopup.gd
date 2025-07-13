extends Control

signal stage_completed
signal game_completed

@onready var stage_label = $PopupContainer/StageLabel
@onready var progress_label = $PopupContainer/ProgressLabel
@onready var continue_button = $PopupContainer/ContinueButton
@onready var background = $Background

var current_stage = 1
var total_stages = 3
var stage_names = ["Stage 1: City Streets", "Stage 2: Industrial Zone", "Stage 3: Final Showdown"]
var is_stage_completed = false

func _ready():
	# Start hidden
	visible = false
	
	# Connect button signal
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	
	# Set up initial stage display
	update_stage_display()

func show_stage_popup(stage_number: int, boss_defeated: bool = false):
	current_stage = stage_number
	is_stage_completed = boss_defeated
	
	# Update display
	update_stage_display()
	
	# Show the popup
	visible = true
	
	# Handle input
	set_process_input(true)
	
	print("Stage popup shown for stage %d (boss defeated: %s)" % [stage_number, str(boss_defeated)])

func update_stage_display():
	if stage_label:
		stage_label.text = stage_names[current_stage - 1]
	
	if progress_label:
		if is_stage_completed:
			if current_stage < total_stages:
				progress_label.text = "Stage %d Complete!\nBoss Defeated!\n\nPress CONTINUE to proceed to Stage %d" % [current_stage, current_stage + 1]
			else:
				progress_label.text = "Stage %d Complete!\nBoss Defeated!\n\nCongratulations! You've completed all stages!" % current_stage
		else:
			progress_label.text = "Stage %d of %d\n\nDefeat the boss to proceed!" % [current_stage, total_stages]
	
	# Show/hide continue button based on completion
	if continue_button:
		continue_button.visible = is_stage_completed and current_stage < total_stages

func _on_continue_pressed():
	if is_stage_completed and current_stage < total_stages:
		# Proceed to next stage
		stage_completed.emit()
		visible = false
		set_process_input(false)
	elif is_stage_completed and current_stage >= total_stages:
		# Game completed
		game_completed.emit()
		visible = false
		set_process_input(false)

func _input(event):
	if event.is_action_pressed("ui_accept") and visible:
		if is_stage_completed and current_stage < total_stages:
			_on_continue_pressed()
		elif is_stage_completed and current_stage >= total_stages:
			_on_continue_pressed()

func show_game_completion():
	stage_label.text = "GAME COMPLETED!"
	progress_label.text = "Congratulations!\nYou've completed all stages!\n\nPress SPACE to return to Main Menu"
	continue_button.visible = false
	visible = true
	set_process_input(true) 
