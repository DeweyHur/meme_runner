# Stage System Documentation

## Overview

The game now features a modular stage system with themed stages instead of simple numbered stages. Each stage has its own unique visual theme, difficulty, and boss encounter.

## Stage Structure

### Base Stage Class (`Stage.gd`)
- **Location**: `scripts/Stage.gd`
- **Purpose**: Base class that all themed stages inherit from
- **Features**:
  - Stage information (name, description, number, difficulty)
  - Boss scene and spawn point management
  - Background music integration
  - Stage completion handling
  - Cleanup functionality

### Stage Manager (`StageManager.gd`)
- **Location**: `scripts/StageManager.gd`
- **Purpose**: Manages stage transitions and loading
- **Features**:
  - Stage definitions and metadata
  - Stage loading and cleanup
  - Stage progression handling
  - Signal management for stage changes

## Themed Stages

### 1. Jungle Stage
- **File**: `scenes/stages/JungleStage.tscn` / `scripts/stages/JungleStage.gd`
- **Theme**: Dense jungle with ancient ruins
- **Difficulty**: 1.0x (Base difficulty)
- **Music**: Cyber Runner theme
- **Visual Elements**:
  - Dark green background
  - Tree silhouettes
  - Rocks and bushes as props
  - Jungle-themed obstacles (planned)

### 2. Cyberpunk Stage
- **File**: `scenes/stages/CyberpunkStage.tscn` / `scripts/stages/CyberpunkStage.gd`
- **Theme**: Neon-lit cityscape with skyscrapers
- **Difficulty**: 1.2x (20% harder)
- **Music**: Cyberpunk Street theme
- **Visual Elements**:
  - Dark blue-black background
  - Skyscrapers with neon lights
  - Neon signs and holographic displays
  - Cyberpunk-themed obstacles (planned)

### 3. Volcano Stage
- **File**: `scenes/stages/VolcanoStage.tscn` / `scripts/stages/VolcanoStage.gd`
- **Theme**: Volcanic landscape with lava and ash
- **Difficulty**: 1.5x (50% harder)
- **Music**: Tung Tung Tung Sahur theme
- **Visual Elements**:
  - Dark brown volcanic background
  - Volcano mountains with lava glow
  - Ash clouds
  - Rocks and lava pools as props

## Integration with Game System

### Game Scene Updates
- Added `StageManager` node to `Game.tscn`
- Updated `Game.gd` to use the new stage system
- Stage transitions now use themed names instead of numbers

### Stage Popup Updates
- Updated to display themed stage names
- Progress messages now show stage names instead of numbers
- Better integration with stage manager

## Usage

### Adding New Stages
1. Create a new stage scene file in `scenes/stages/`
2. Create a corresponding script in `scripts/stages/` that extends `Stage`
3. Override the `setup_stage()` method to add stage-specific content
4. Add the stage to the `stages` array in `StageManager.gd`

### Stage Configuration
Each stage can be configured with:
- **stage_name**: Display name for the stage
- **stage_description**: Description shown in UI
- **stage_number**: Order in the stage sequence
- **boss_scene**: Scene file for the stage boss
- **background_music**: Audio file for stage music
- **difficulty_multiplier**: Difficulty scaling factor

## Benefits

1. **Modularity**: Each stage is self-contained and can be easily modified
2. **Theming**: Visual and audio themes create distinct gameplay experiences
3. **Scalability**: Easy to add new stages without modifying core game logic
4. **Maintainability**: Stage-specific code is isolated and organized
5. **User Experience**: Themed names are more engaging than numbered stages

## Future Enhancements

- Stage-specific obstacles and enemies
- Dynamic background music changes
- Stage-specific power-ups or mechanics
- Weather effects and particle systems
- Stage-specific UI themes 