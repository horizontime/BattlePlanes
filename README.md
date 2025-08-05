# BattlePlanes

A fast-paced multiplayer aerial combat game built with Godot 4.4. Battle against friends in various game modes including Free-For-All and Team-based matches!

## Demo Screenshots

[Host creating server](demo-pics/pic1.PNG)  
[Halo style FFA and team game modes](demo-pics/pic2.PNG)  
[FFA lobby](demo-pics/pic3.PNG)  
[Players can join lobby](demo-pics/pic4.PNG)  
[Multiple players in lobby](demo-pics/pic5.PNG)  
[Multiple players in FFA game](demo-pics/pic6.PNG)  
[Team game lobby](demo-pics/pic7.PNG)  
[Team game gameplay](demo-pics/pic8.PNG)

## Features

- **Multiplayer Support**: Host games for up to 8 players
- **Multiple Game Modes**:
  - **Slayer**: Classic slayer (FFA or Team)
  - **Oddball**: Hold the skull to score points
  - **King of the Hill**: Control the hill zone to win
- **Team Battles**: Form teams and compete in objective-based modes
- **Customizable Settings**: Adjust player lives, speed, damage, and time limits
- **Weapon Heat System**: Strategic shooting with overheating mechanics
- **Dynamic Gameplay**: Screen wrapping, power-ups, and respawn system


## Requirements

- Godot Engine 4.4 or higher
- Windows, macOS, or Linux
- Network connection for multiplayer

## Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/BattlePlanes.git
   cd BattlePlanes
   ```

2. **Open in Godot**:
   - Launch Godot Engine 4.4+
   - Click "Import" and select the `project.godot` file
   - Open the project

3. **Run the game**:
   - Press F5 to run the full game
   - Press F6 to run the current scene

## How to Play

### Controls
- **W/S**: Throttle up/down
- **A/D**: Turn left/right
- **Space**: Shoot
- **ESC**: Pause/Menu (when applicable)

### Starting a Game

1. **Host a Game**:
   - Click "Host"
   - Enter your username and port (default: 8910)
   - Configure game settings (mode, lives, speed, etc.)
   - Start from lobby when players join

2. **Join a Game**:
   - Click "Join"
   - Enter host IP address and port
   - Enter your username
   - Wait in lobby for host to start

### Game Modes

#### Slayer (FFA/Team)
- Eliminate opponents to score points
- First to reach kill limit wins
- Team mode: Work together to outscore the enemy team

#### Oddball (FFA/Team)
- Pick up and hold the skull to accumulate points
- Skull holder is marked and vulnerable
- First to 60 points wins (100 for teams)

#### King of the Hill (FFA/Team)
- Control the marked hill zone to score
- Hill moves periodically
- First to 60 points wins (100 for teams)

## Multiplayer Setup

### Local Network
1. Host player starts a server with desired settings
2. Share IP address with other players
3. Other players join using the IP and port

### Testing Locally
1. Run multiple instances of Godot
2. One instance hosts, others join via `localhost` or `127.0.0.1`

### Dedicated Server
Run headless server for better performance:
```bash
godot --path . --headless
```

## Project Structure

```
BattlePlanes/
├── Scenes/          # Game scenes (.tscn files)
│   ├── Main.tscn    # Main game scene
│   ├── Player.tscn  # Player plane
│   └── ...
├── Scripts/         # GDScript source files
│   ├── GameManager.gd
│   ├── NetworkManager.gd
│   ├── Player.gd
│   └── ...
├── Sprites/         # Visual assets
│   ├── Ships/       # Player plane sprites
│   └── Tiles/       # Environment sprites
├── Audio/           # Sound effects
└── project.godot    # Project configuration
```

## Development

### Building from Source
1. Open project in Godot 4.4+
2. Go to Project → Export
3. Select your target platform
4. Configure export settings
5. Click "Export Project"

### Contributing
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## Configuration

### Server Settings
- **Max Players**: 2-8 players
- **Player Lives**: 1-10 lives per round
- **Speed Multiplier**: 0.5x - 2.0x movement speed
- **Damage Multiplier**: 0.5x - 2.0x weapon damage
- **Time Limit**: Optional, 5-30 minutes
- **Kill Limit**: Points needed to win Slayer mode

### Advanced Settings
Edit `project.godot` for engine configuration:
- Input mappings
- Rendering settings
- Network parameters

**Enjoy the aerial combat!** 🛩️💥