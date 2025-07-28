# Slope Movement Implementation

## Overview
This implementation allows the player to move smoothly on gradual decline slopes instead of falling through them. The system detects slope angles and applies appropriate vertical movement to keep the player on the ground surface.

## Key Features

### 1. Slope Detection
- **Method**: `detect_slope_info()` in `Player/player.gd`
- **Process**: 
  - Gets ground information from the procedural ground system
  - Calculates slope angle from the ground normal vector
  - Determines if slope is upward or downward based on normal direction
  - Stores current slope angle and normal for movement calculations

### 2. Slope Movement Logic
- **Method**: `handle_slope_movement(delta)` in `Player/player.gd`
- **Behavior**:
  - For downward slopes (negative angles): Applies gentle downward velocity
  - For upward slopes: Maintains current Y velocity (gravity handles it)
  - Prevents falling through ground by checking ground height
  - Only applies to slopes within walkable angle range (25° by default)

### 3. Integration with Existing Systems
- **Procedural Ground**: Uses existing `get_ground_info_at_position()` method
- **Ground Pieces**: Leverages `get_ground_info_at_x()` for detailed slope information
- **Debug Overlay**: Added slope information display for testing

## Configuration

### Slope Parameters
```gdscript
var max_walkable_slope_angle = 25.0  # Maximum walkable slope angle
var slope_movement_enabled = true    # Enable/disable slope movement
var debug_slope_info = false         # Enable debug output
```

### How It Works

1. **Detection Phase**:
   - When player is on floor, `detect_slope_info()` is called
   - Gets ground normal from procedural ground system
   - Calculates slope angle using `acos(normal.y)`
   - Determines slope direction (upward/downward)

2. **Movement Phase**:
   - If slope angle ≤ 25° and slope movement is enabled:
     - For downward slopes: `velocity.y = run_speed * sin(slope_angle)`
     - For upward slopes: `velocity.y = 0` (let gravity handle it)
   - Otherwise: Normal gravity applies

3. **Ground Collision**:
   - Checks if player would fall through ground
   - Adjusts position to stay on ground surface

## Debug Features

### Console Output
Enable `debug_slope_info = true` to see:
- Slope detection messages
- Downhill movement calculations
- Current slope angles and velocities

### Visual Debug
Press F1 in game to toggle debug overlay showing:
- Current slope angle
- Slope normal vector
- Slope movement status
- Ground collision information

## Benefits

1. **Smooth Movement**: Player follows gradual slopes naturally
2. **No Falling**: Prevents falling through gradual decline slopes
3. **Configurable**: Easy to adjust slope angles and behavior
4. **Performance**: Minimal overhead, only runs when on floor
5. **Compatible**: Works with existing procedural ground system

## Testing

To test the implementation:
1. Run the game
2. Press F1 to enable debug overlay
3. Run forward until you encounter downhill slopes
4. Observe smooth movement instead of falling
5. Check debug information for slope angles and movement

## Future Enhancements

- Add slope sound effects
- Implement slope-based animation adjustments
- Add slope friction/speed modifiers
- Create slope-specific visual effects 