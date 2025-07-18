# AGENT.md - Godot BattlePlanes Project Guide

## Build/Test Commands
- Run project: Open in Godot Editor 4.4.1 and press F5, or use `godot --path . --headless` for server
- Debug: Use Godot Editor's built-in debugger (F5 for play, F6 for play scene)
- Export: Project > Export from Godot Editor menu

## Architecture
- **Engine**: Godot 4.4.1 (GDScript) multiplayer game
- **Main Scene**: `Scenes/Main.tscn` - Entry point and game coordinator
- **Core Systems**: 
  - `Scripts/NetworkManager.gd` - Multiplayer networking, server/client management
  - `Scripts/GameManager.gd` - Game logic, player management, game modes (Oddball, KOTH)
  - `Scripts/Player.gd` - Player controller with physics, shooting, health system
- **Game Objects**: Projectiles, Hearts (powerups), Skulls (oddball), Hills (KOTH)

## Code Style & Conventions
- **Language**: GDScript (Godot's Python-like scripting language)
- **Naming**: snake_case for variables/functions, PascalCase for classes/scenes
- **File Organization**: Scripts in `/Scripts/`, Scenes in `/Scenes/`, Sprites in `/Sprites/`
- **Node Structure**: Use `@onready` for node references, `@export` for inspector properties
- **Multiplayer**: Use `@rpc` decorators for network calls, authority-based synchronization
- **Binary Data**: Never edit PackedByteArray or binary functions per .cursor rules
- **Commit Style**: Use conventional commits: `type(scope): description` format
