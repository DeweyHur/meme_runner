# Development Conventions

## Git Workflow

### Commit and Push Command
The project uses a shorthand convention for committing and pushing changes:

```bash
# Use 'c' as a shorthand for commit and push
c
```

This command performs the following operations:
1. `git add .` - Stage all changes
2. `git commit -m "descriptive message"` - Commit with a descriptive message
3. `git push` - Push to remote repository

### Commit Message Format
When using the 'c' command, follow this commit message format:

```
Brief description of changes

- Key change 1
- Key change 2
- Key change 3
```

Example:
```
Refactor stage system to use proper GDScript inheritance

- Add class_name Stage to base class for better type safety
- Refactor JungleStage, CyberpunkStage, and VolcanoStage to extend Stage
- Remove code duplication (75% reduction in each stage script)
- Fix signal name consistency (stage_completed_signal)
- Add ExampleStage.gd demonstrating inheritance patterns
- Create comprehensive STAGE_INHERITANCE_GUIDE.md documentation
- Improve maintainability and extensibility of stage system
```

## Code Style

### GDScript Conventions
- Use `class_name` for global class definitions
- Use `extends` for inheritance
- Use `super` to call parent methods
- Use descriptive variable and function names
- Add comments for complex logic

### File Organization
- Keep related files in appropriate directories
- Use descriptive file names
- Group similar functionality together

## Documentation
- Update README.md for major feature changes
- Create specific documentation files for complex systems
- Include examples in documentation
- Keep documentation up to date with code changes

## Testing
- Test changes before committing
- Verify that existing functionality still works
- Test edge cases and error conditions 