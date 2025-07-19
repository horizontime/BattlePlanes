# Lobby System Documentation

## Overview
The lobby system provides a waiting area for players before starting a game. Players can see who's joined and the host can start the game when ready.

## How It Works

### For Host (Server)
1. Click "Configure Server" button in main menu
2. Choose game mode and settings in server configuration
3. Click "Start Server" - this now creates a lobby instead of starting the game immediately
4. Lobby appears with appropriate UI (FFA or Team mode)
5. Host can see all connected players
6. Host clicks "Start Game" to begin the match

### For Clients
1. Enter IP and port of host
2. Click "Join Server"
3. Automatically joins the lobby
4. Can see other players and game mode
5. Waits for host to start the game

## Lobby Types

### FFA Lobby
- Shows all players in a single list
- Used for: FFA Slayer, Last Man Standing, Oddball, King of the Hill
- Players compete individually

### Team Lobby
- Shows players divided into Team A and Team B
- Used for: Team Slayer, Capture The Flag
- Automatic team assignment: odd player IDs → Team A, even player IDs → Team B

## Key Features
- Real-time player list updates
- Player count display (current/max)
- Host indicators
- Team assignment for team modes
- Proper cleanup when lobby closes
- Seamless transition to game

## Implementation Files
- `Scripts/LobbyManager.gd` - Base lobby functionality
- `Scripts/TeamLobbyManager.gd` - Team-specific lobby features
- `Scenes/FFALobby.tscn` - FFA lobby UI
- `Scenes/TeamLobby.tscn` - Team lobby UI
- `Scripts/NetworkManager.gd` - Updated network flow with lobby support

## Network Flow
1. Host configures server → Creates lobby
2. Clients join → Receive lobby state
3. Host starts game → All players transition to game
4. Lobby closes → Game begins

## Testing
To test the lobby system:
1. Open project in Godot Editor
2. Run the game (F5)
3. Configure and start a server
4. In a second instance, join the server
5. Verify lobby appears with correct player list
6. Start game from lobby and verify transition
