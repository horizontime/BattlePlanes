# Manual Test Guide: Automatic Return Flow (Step 6)

This guide provides step-by-step instructions to manually test the automatic return flow functionality.

## Test Scenario Overview

**Objective**: Verify that after a win condition is triggered, the EndScreen shows the winner with a "Returning to lobby in 4…3…2…1…0" countdown, and after 4 seconds the server automatically calls `_return_to_lobby()` with all peers returning to the lobby scene.

## Prerequisites

1. Godot Engine 4.4+ installed
2. BattlePlanes project loaded in Godot
3. Access to multiple instances (for server + clients)

## Step-by-Step Manual Testing

### Step 1: Set Up Server and Clients

1. **Open Godot Editor**
   - Load the BattlePlanes project
   - Open `Scenes/Main.tscn`

2. **Start Server Instance**
   - Run the project (F5)
   - Click "Host Game" button
   - Set up game configuration (any game mode works)
   - Note: Server instance is ready

3. **Start Client Instances (1-3 clients)**
   - Open additional Godot editor windows or export/run multiple instances
   - In each client instance:
     - Run the project
     - Click "Join Game"
     - Enter server IP (usually 127.0.0.1 for local testing)
     - Connect to the server

4. **Verify Connection**
   - ✅ All players should appear in the lobby
   - ✅ Server can see all connected clients
   - ✅ No connection errors in console

### Step 2: Start a Game and Trigger Win Condition

1. **Start Game from Server**
   - On server instance, click "Start Game"
   - Game should begin with all players spawned

2. **Trigger Win Condition (Choose One Method)**

   **Method A: Elimination Win**
   - Have all players except one eliminate themselves/others
   - Last player standing wins

   **Method B: Score Limit Win** 
   - Play until one player reaches the kill limit (default 15)
   - First to reach limit wins

   **Method C: Oddball Win** (if oddball mode enabled)
   - Collect and hold the skull for required time
   - Reach 60 oddball points to win

   **Method D: King of the Hill Win** (if KOTH mode enabled)
   - Control the hill area
   - Reach 60 KOTH points to win

   **Method E: Time Limit Win** (if time limit enabled)
   - Wait for time limit to expire
   - Player with highest score wins

### Step 3: Verify EndScreen Display and Countdown

When win condition is triggered, verify:

1. **EndScreen Appears**
   - ✅ EndScreen becomes visible on ALL instances (server + clients)
   - ✅ Winner text displays correctly: "[Player Name] wins!"
   - ✅ For special modes: "[Player Name] (King of the Hill Winner)" etc.

2. **Countdown Label Appears**
   - ✅ Countdown label is visible
   - ✅ Shows: "Returning to lobby in 4..."
   - ✅ Updates every second: "Returning to lobby in 3..."
   - ✅ Continues: "Returning to lobby in 2..."
   - ✅ Then: "Returning to lobby in 1..."
   - ✅ Finally: "Returning to lobby in 0..."

3. **Button Visibility**
   - ✅ "Play Again" button is NOT visible during countdown
   - ✅ Only the countdown text is shown

### Step 4: Verify Automatic Lobby Return

After the 4-second countdown completes:

1. **Server Automatically Calls Return**
   - ✅ Server should automatically trigger `_return_to_lobby()`
   - ✅ No manual button click required
   - ✅ Process happens automatically at countdown end

2. **Scene Transition**
   - ✅ ALL instances (server + clients) return to Main scene
   - ✅ Lobby UI is restored
   - ✅ Scene transition happens simultaneously

3. **Player List Preservation**
   - ✅ All previously connected players remain in lobby
   - ✅ Player names are preserved
   - ✅ Connection status maintained
   - ✅ Ready to start a new game

### Step 5: Console Error Check

Monitor the console output on both server and client instances:

1. **During Game Play**
   - ✅ No errors during normal gameplay
   - ✅ No RPC timeout errors
   - ✅ No networking sync issues

2. **During Win Condition Trigger**
   - ✅ No errors when game ends
   - ✅ No issues with EndScreen display
   - ✅ Countdown timer works without errors

3. **During Automatic Return**
   - ✅ No scene loading errors
   - ✅ No node path errors during transition
   - ✅ No NetworkManager errors
   - ✅ Clean return to lobby state

## Expected Results Summary

If all tests pass, you should observe:

✅ **Server Setup**: 1 server + 1-3 clients connected successfully
✅ **Win Condition**: Any win condition can be triggered properly  
✅ **EndScreen Display**: Winner shown with "Returning to lobby in 4…3…2…1…0" countdown
✅ **Automatic Return**: After exactly 4 seconds, server calls `_return_to_lobby()`
✅ **Scene Transition**: All peers automatically change back to lobby scene
✅ **No Errors**: Console remains clean throughout the process

## Troubleshooting

**If EndScreen doesn't appear:**
- Check `GameManager.end_game_clients()` RPC calls
- Verify EndScreen node path in Main scene

**If countdown doesn't work:**
- Check `_on_lobby_countdown_tick()` function
- Verify lobby_countdown_timer setup

**If automatic return fails:**
- Check `multiplayer.is_server()` permissions
- Verify `_return_to_lobby()` function execution

**If clients don't return to lobby:**
- Check NetworkManager RPC calls
- Verify scene transition synchronization

## Code References

Key functions involved in this flow:
- `GameManager.end_game_clients()` - Displays EndScreen and starts countdown
- `GameManager._on_lobby_countdown_tick()` - Handles countdown updates  
- `GameManager._return_to_lobby()` - Server-only function that triggers return
- `NetworkManager.return_to_lobby()` - Handles network synchronization
- `NetworkManager._transition_to_lobby()` - Client-side lobby restoration

## Test Completion

When all steps pass successfully, the automatic return flow is working correctly and meets the requirements of Step 6.
