# Procedural Ground Generation System

This system creates dynamic, procedurally generated terrain for the meme runner game. Instead of a static ground, the terrain is generated on-the-fly as the player moves forward.

## Features

### Terrain Types
- **Normal**: Standard terrain with gentle height variations
- **Uphill**: Gradual upward slopes that players can walk up without jumping
- **Downhill**: Gradual downward slopes that players can walk down without jumping
- **Hills**: Elevated terrain with parabolic hill shapes (require jumping)
- **Valleys**: Lowered terrain with inverted parabolic valley shapes (require jumping)
- **Plateaus**: Flat terrain with smooth edges
- **Bumpy**: Terrain with noise-based height variations

### Visual Details
- **Color Gradients**: Ground color changes based on height and terrain type
- **Terrain Details**: Rocks on hills, grass in valleys, texture on plateaus
- **Smooth Transitions**: Terrain smoothly transitions between different types

### Performance Features
- **Memory Management**: Old terrain segments are automatically cleaned up
- **Efficient Generation**: Only generates terrain ahead of the player
- **Configurable Parameters**: Easy to adjust terrain complexity and appearance

## Configuration

The `ProceduralGround.gd` script has several export variables you can adjust:

- `segment_width`: Width of each terrain segment (default: 200.0)
- `ground_height`: Height of the ground collision (default: 50.0)
- `max_height_variation`: Maximum height change between segments (default: 100.0)
- `min_segment_length`: Minimum number of pieces per segment (default: 3)
- `max_segment_length`: Maximum number of pieces per segment (default: 8)
- `smoothness`: How smooth transitions are (0-1, default: 0.3)
- `terrain_complexity`: Overall complexity of terrain (default: 0.7)
- `max_walkable_slope`: Maximum slope angle in degrees that player can walk up (default: 25.0)
- `slope_segment_length`: How many segments to use for gradual slopes (default: 6)
- `walkable_height_threshold`: Height difference threshold for automatic slope conversion (default: 30.0)

## How It Works

1. **Initial Generation**: Creates 5 segments of terrain when the game starts
2. **Dynamic Generation**: Monitors player position and generates new segments when needed
3. **Terrain Selection**: Randomly chooses terrain types with weighted probabilities
4. **Height Calculation**: Uses different algorithms for each terrain type
5. **Slope Generation**: Creates walkable slopes with gradual height changes
6. **Visual Creation**: Generates collision shapes and visual elements
7. **Cleanup**: Removes old segments to maintain performance

## Walkable Slopes

The system now includes **uphill** and **downhill** slopes that players can traverse without jumping:
- **Gradual Inclines**: Smooth upward slopes that don't require jumping
- **Gradual Declines**: Smooth downward slopes that don't require jumping
- **Configurable Angle**: Adjust `max_walkable_slope` to control maximum walkable angle
- **Smooth Transitions**: Slopes use longer segments for gradual height changes
- **Automatic Conversion**: Small height differences (< 30 units) are automatically converted to walkable slopes
- **Smart Terrain**: Reduces jump-required terrain for smoother gameplay

## Usage

The procedural ground system is automatically integrated into the Game scene. Simply run the game and the terrain will be generated as you move forward.

## Customization

To add new terrain types:
1. Add the terrain type to `choose_terrain_type()`
2. Add height calculation logic to `calculate_height_change()`
3. Add visual generation logic to `calculate_piece_height()`
4. Add color logic to `calculate_ground_color()`
5. Add detail generation to `add_terrain_details()`

## Performance Tips

- Adjust `max_segments` to control memory usage
- Modify `segment_width` to balance detail vs performance
- Use `terrain_complexity` to control overall generation complexity 