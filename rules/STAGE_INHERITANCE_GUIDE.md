# Stage Inheritance System Guide

## Overview

The stage system now uses proper GDScript inheritance to share common logic among all stages. This eliminates code duplication and makes it easy to create new stages.

## How GDScript Inheritance Works

### Basic Syntax
```gdscript
# Base class
extends Node2D
class_name Stage

# Derived class
extends Stage
class_name JungleStage
```

### Key Inheritance Features in GDScript

1. **`extends`**: Specifies the parent class
2. **`class_name`**: Creates a global class name for easy reference
3. **`super`**: Calls parent class methods
4. **Method overriding**: Redefine parent methods in child classes
5. **Virtual methods**: Use `@warning_ignore("unused_parameter")` for methods meant to be overridden

## Base Stage Class (`Stage.gd`)

The base class provides common functionality for all stages:

### Common Properties
- `stage_name`: Display name of the stage
- `stage_description`: Description for UI display
- `stage_number`: Stage order/number
- `boss_scene`: Boss enemy scene
- `background_music`: Stage music
- `difficulty_multiplier`: Difficulty scaling factor

### Common Methods
- `setup_stage()`: Virtual method for stage-specific setup
- `spawn_boss()`: Boss spawning logic
- `complete_stage()`: Stage completion handling
- `cleanup_stage()`: Resource cleanup
- Getter methods for stage information

### Common Variables
- `boss_spawned`, `boss_active`, `stage_completed`: State tracking
- Node references: `parallax_background`, `ground`, `obstacles`, etc.

## Creating a New Stage

### Step 1: Create the Script
```gdscript
extends Stage
class_name MyNewStage

func _ready():
    # Set stage-specific information
    stage_name = "My New Stage"
    stage_description = "A cool new stage"
    stage_number = 5
    difficulty_multiplier = 2.0
    
    # Call parent initialization
    super._ready()

func setup_stage():
    # Stage-specific setup
    setup_my_obstacles()
    setup_my_props()

func setup_my_obstacles():
    # Create stage-specific obstacles
    pass

func setup_my_props():
    # Create stage-specific props
    pass
```

### Step 2: Create the Scene
1. Create a new scene file (`.tscn`)
2. Set the root node to Node2D
3. Attach your stage script
4. Add the required child nodes:
   - `ParallaxBackground`
   - `Ground`
   - `Obstacles`
   - `Enemies`
   - `Props`
   - `BossSpawnPoint`

### Step 3: Register in StageManager
Add your stage to the `stages` array in `StageManager.gd`:
```gdscript
var stages = [
    # ... existing stages ...
    {
        "name": "My New Stage",
        "scene_path": "res://scenes/stages/MyNewStage.tscn",
        "description": "A cool new stage",
        "difficulty": 2.0
    }
]
```

## Inheritance Benefits

### 1. Code Reuse
- Common logic is defined once in the base class
- No need to duplicate boss spawning, cleanup, or getter methods
- Consistent behavior across all stages

### 2. Easy Maintenance
- Bug fixes in base class automatically apply to all stages
- New features can be added to base class for all stages
- Consistent interface across all stages

### 3. Type Safety
- Using `class_name` provides better type checking
- IDE autocomplete works better
- Easier to catch errors at compile time

### 4. Polymorphism
- All stages can be treated as `Stage` objects
- Easy to iterate through stages or pass them to functions
- Consistent method calls regardless of specific stage type

## Advanced Inheritance Patterns

### Method Overriding
```gdscript
# Override parent method
func spawn_boss() -> Node2D:
    # Call parent method first
    var boss = super.spawn_boss()
    
    # Add stage-specific behavior
    if boss:
        add_special_effects(boss)
    
    return boss
```

### Adding Stage-Specific Methods
```gdscript
# Stage-specific functionality
func trigger_special_event():
    # Only available in this stage
    pass
```

### Conditional Behavior
```gdscript
func setup_stage():
    # Call parent setup
    super.setup_stage()
    
    # Add conditional stage-specific setup
    if difficulty_multiplier > 1.5:
        setup_hard_mode_obstacles()
```

## Best Practices

### 1. Always Call Parent Methods
```gdscript
func _ready():
    # Set stage-specific properties first
    stage_name = "My Stage"
    
    # Always call parent _ready()
    super._ready()
```

### 2. Use Virtual Methods for Override Points
```gdscript
# In base class
func setup_stage():
    # Override this in derived stages
    pass

# In derived class
func setup_stage():
    # Stage-specific setup
    setup_my_obstacles()
```

### 3. Keep Stage-Specific Code Minimal
- Only override what's necessary
- Use base class functionality when possible
- Focus on theme-specific content

### 4. Consistent Naming
- Use consistent method names across stages
- Follow the established pattern for setup methods
- Use descriptive names for stage-specific methods

## Troubleshooting

### Common Issues

1. **"Method not found" errors**: Make sure you're calling `super._ready()` in derived classes
2. **Node references not working**: Ensure child nodes exist in the scene tree
3. **Inheritance not working**: Check that the script extends `Stage` and not `Node2D`

### Debug Tips

1. Add debug prints to verify inheritance:
```gdscript
func _ready():
    print("My stage is ready!")
    super._ready()
```

2. Check class types:
```gdscript
if my_stage is Stage:
    print("Stage inheritance working!")
```

3. Verify method calls:
```gdscript
func setup_stage():
    print("Setting up my stage...")
    super.setup_stage()
```

## Example: Complete Stage Implementation

See `scripts/stages/ExampleStage.gd` for a complete example of how to create a new stage using inheritance. 