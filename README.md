# Meme Runner

A fun runner game inspired by Cookie Run! Run through the platform, avoid obstacles, and try to get the highest score.

## How to Play

### Controls
- **SPACE** or **UP ARROW**: Jump over high obstacles
- **DOWN ARROW**: Slide under low obstacles
- **R**: Restart the game after game over

### Gameplay
- Your character automatically runs forward
- Avoid obstacles by jumping or sliding
- Score increases based on distance traveled
- Game speed increases over time
- Colliding with obstacles ends the game

### Obstacle Types
- **Red rectangles**: High obstacles - jump over them
- **Orange rectangles**: Low obstacles - slide under them
- **Double red rectangles**: Both high and low - requires precise timing

## Features
- Smooth running animation
- Dynamic obstacle spawning
- Progressive difficulty increase
- Score tracking
- Game over screen with restart option

## Development
This game is built with Godot 4.4 and uses:
- CharacterBody2D for player physics
- StaticBody2D for obstacles and ground
- Timer nodes for obstacle spawning
- CanvasLayer for UI elements

## Ground Generation Rules

### Edge Height Precomputation (CRITICAL)

**ALWAYS use precomputed edge heights for seamless ground connections:**

1. **For N ground pieces, calculate N+1 edge heights:**
   ```gdscript
   var edge_heights = []
   for i in range(length + 1):  # N+1 for N pieces
       var progress = float(i) / float(length)
       var edge_height = calculate_edge_height(progress, terrain_type)
       edge_heights.append(edge_height)
   ```

2. **Each piece uses exact edge heights:**
   ```gdscript
   var left_height = edge_heights[index]
   var right_height = edge_heights[index + 1]
   ```

3. **NEVER calculate piece heights individually** - this causes connection mismatches.

4. **NEVER use prev/next/center height logic** for edge calculation.

5. **Validation must check actual polygon points** from collision shapes.

**Why this matters:** Individual piece height calculation leads to gaps where piece N's right edge ≠ piece N+1's left edge, causing player to fall through or get stuck.

**Example of WRONG approach (causes gaps):**
```gdscript
# DON'T DO THIS
for i in range(length):
    var height = calculate_piece_height(i, length, terrain_type)
    # This creates mismatched edges between pieces
```

**Example of CORRECT approach (seamless connections):**
```gdscript
# DO THIS
var edge_heights = []
for i in range(length + 1):
    var progress = float(i) / float(length)
    var edge_height = calculate_edge_height(progress, terrain_type)
    edge_heights.append(edge_height)

for i in range(length):
    var left_height = edge_heights[i]
    var right_height = edge_heights[i + 1]
    # Guaranteed to connect perfectly
```

### Ground Collision Rules

1. Use positive Y (downward) for all ground, collision, and visual shapes in Godot 2D.
2. Collision shapes and visuals must use the same polygon points and orientation; top edge is the walkable surface.
3. Each ground piece must be a sloped polygon, not a flat rectangle; left/right heights must match adjacent pieces.
4. Normals must be calculated perpendicular to the top edge and visualized at its center, pointing away from the ground.
5. Debug overlays/visualizers must use actual polygon points from the collision shape, never assume a rectangle or hardcoded normal.
6. Debug info must include polygon points, slope angle, normal vector, and connection validation.
7. Validate that each piece's right edge matches the next piece's left edge (within tolerance); warn if not.
8. Player should only interact with the top edge of the ground polygon; never fall through or float above if rules are followed.

If any rule is violated (e.g., flat rectangles, negative Y for ground, mismatched collision/visual, or normals not matching the slope), STOP and fix before proceeding.

## Features

- Procedural ground generation with multiple terrain types
- Smooth player movement on slopes
- Dynamic camera following
- Debug overlays for development
- Multiple terrain types: normal, hills, valleys, plateaus, bumpy, uphill, downhill

## Controls

- Use arrow keys or WASD to move
- Jump with Space
- Debug info is displayed on screen during development

## Development
This project uses Godot 4. Make sure to follow the ground generation rules above when making changes to the procedural terrain system.

Enjoy playing Meme Runner! 