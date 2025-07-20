extends Node

var players : Array[Player]
var local_player : Player

# Team management for team-based game modes
var team_assignments: Dictionary = {}  # player_id -> team (0 = Team A, 1 = Team B)
var is_team_mode: bool = false
var team_kill_scores: Dictionary = {0:0, 1:0}  # team kill scores for team-based modes

# Game mode constants
const MODE_TEAM_ODDBALL = "Team Oddball"
const MODE_TEAM_KOTH = "Team King of the Hill"

# Game Mode Mapping Table
# This table defines how radio button selections map to game modes based on TeamMode setting:
#
# Radio         | TeamMode off                | TeamMode on
# --------------|----------------------------|---------------------------
# Slayer        | "FFA Slayer", type "ffa"   | "Team Slayer", type "team"
# Oddball       | "Oddball", type "ffa"      | "Team Oddball", type "team"
# KOTH          | "King of the Hill", type "ffa" | "Team King of the Hill", type "team"

# Game configuration settings
var player_lives : int = 3
var max_players : int = 4
var speed_multiplier : float = 1.0
var damage_multiplier : float = 1.0
var has_time_limit : bool = false
var time_limit_minutes : int = 10

var clouds_enabled : bool = true
var oddball_mode : bool = false
var koth_mode : bool = false
var game_mode : String = ""
var game_mode_type : String = ""
var kill_limit : int = 15



# Oddball mode management
var skull_scene = preload("res://Scenes/Skull.tscn")
var current_skull : Skull = null
var skull_holder : Player = null
var oddball_score_timer : Timer
var oddball_win_score : int = 60

# Team Oddball mode variables
const TEAM_A = 0
const TEAM_B = 1
var team_skull_time: Dictionary = {TEAM_A: 0, TEAM_B: 0}
var player_kills: Dictionary = {}  # player_id -> kill count
var last_team_time_update: float = 0.0  # Track when we last sent RPC update

# KOTH mode management
var hill_scene = preload("res://Scenes/Hill.tscn")
var current_hill : Hill = null
var hill_movement_timer : Timer
var koth_score_timer : Timer
var koth_win_score : int = 60

# Team KOTH mode variables
var team_hill_time: Dictionary = {TEAM_A: 0, TEAM_B: 0}
var team_koth_win_score : int = 100

# Time limit tracking
var time_limit_seconds : float = 0.0
var game_timer : Timer

var min_x : float = -400
var max_x : float = 400
var min_y : float = -230
var max_y : float = 230

# Health bar management
var health_bar_scene = preload("res://Scenes/HealthBar.tscn")
var health_bars : Array[HealthBar] = []

# Lobby countdown variables
var lobby_countdown_seconds : int = 4
var lobby_countdown_timer : Timer
@onready var lobby_countdown_label = $"../EndScreen/CountdownLabel"

@onready var camera_shake = $"../Camera2D"

# end screen
@onready var end_screen = $"../EndScreen"
@onready var end_screen_winner_text = $"../EndScreen/WinText"
@onready var end_screen_button = $"../EndScreen/PlayAgainButton"

# timer UI
@onready var timer_ui = $"../TimerUI"
@onready var timer_label = $"../TimerUI/TimerLabel"

# game UI elements that should be hidden until game starts
@onready var score_ui = $"../ScoreUI"
@onready var weapon_heat_bar = $"../WeaponHeatBar"
@onready var cooldown_label = $"../CooldownLabel"

# environment elements
@onready var clouds = $"../Environment/Clouds"

func _ready():
	# Create a timer to periodically check for new players and create health bars
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(_check_for_new_players)
	timer.autostart = true
	add_child(timer)
	
	
	# Create game timer for time limits
	game_timer = Timer.new()
	game_timer.wait_time = 1.0  # Update every second
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)
	

	
	# Create oddball score timer
	oddball_score_timer = Timer.new()
	oddball_score_timer.wait_time = 1.0  # 1 second
	oddball_score_timer.timeout.connect(_on_oddball_score_timer)
	add_child(oddball_score_timer)
	
	# Create KOTH timers
	hill_movement_timer = Timer.new()
	hill_movement_timer.wait_time = 30.0  # 30 seconds
	hill_movement_timer.timeout.connect(_on_hill_movement_timer)
	add_child(hill_movement_timer)
	
	koth_score_timer = Timer.new()
	koth_score_timer.wait_time = 1.0  # 1 second
	koth_score_timer.timeout.connect(_on_koth_score_timer)
	add_child(koth_score_timer)
	
	# Create lobby countdown timer
	lobby_countdown_timer = Timer.new()
	lobby_countdown_timer.one_shot = false
	lobby_countdown_timer.wait_time = 1.0
	lobby_countdown_timer.timeout.connect(_on_lobby_countdown_tick)
	add_child(lobby_countdown_timer)
	
	# Initialize team kill scores
	team_kill_scores = {0:0, 1:0}

func _process(delta):
	# Check if multiplayer instance is active
	if not multiplayer.get_multiplayer_peer():
		return
		
	# Team Oddball server-authoritative time tracking
	if multiplayer.is_server() and game_mode == MODE_TEAM_ODDBALL and skull_holder and is_instance_valid(skull_holder):
		var holder_team = skull_holder.team
		team_skull_time[holder_team] += delta
		
		# Broadcast team time update every second
		last_team_time_update += delta
		if last_team_time_update >= 1.0:
			last_team_time_update = 0.0
			update_team_oddball_time.rpc(TEAM_A, team_skull_time[TEAM_A])
			update_team_oddball_time.rpc(TEAM_B, team_skull_time[TEAM_B])
		
		# Check win condition on time gain
		_check_team_oddball_win()
	
	# Also check elapsed time win conditions for Team Oddball
	if multiplayer.is_server() and game_mode == MODE_TEAM_ODDBALL and has_time_limit:
		_check_team_oddball_time_limit()

func apply_server_config(config: Dictionary):
	"""Apply server configuration settings to the game"""
	player_lives = config.get("player_lives", 3)
	max_players = config.get("max_players", 4)
	speed_multiplier = config.get("speed_multiplier", 1.0)
	damage_multiplier = config.get("damage_multiplier", 1.0)
	has_time_limit = config.get("has_time_limit", false)
	time_limit_minutes = config.get("time_limit_minutes", 10)

	clouds_enabled = config.get("clouds_enabled", true)
	oddball_mode = config.get("oddball_mode", false)
	koth_mode = config.get("koth_mode", false)
	game_mode = config.get("game_mode", "")
	game_mode_type = config.get("game_mode_type", "")
	kill_limit = config.get("kill_limit", 15)
	
	# Send configuration to all clients
	if multiplayer.is_server():
		_apply_server_config_clients.rpc(config)
	
	# Start time limit if enabled
	if has_time_limit:
		time_limit_seconds = time_limit_minutes * 60.0
		if multiplayer.is_server():
			game_timer.start()
		_show_timer_ui()
	else:
		_hide_timer_ui()
	

	
	# Team Oddball initialization
	if game_mode == MODE_TEAM_ODDBALL and multiplayer.is_server():
		# Initialize team skull time
		team_skull_time = {TEAM_A: 0, TEAM_B: 0}
		# Initialize player kills - ensure all current and future players are tracked
		if not player_kills:
			player_kills = {}
		for player in players:
			if not player_kills.has(player.player_id):
				player_kills[player.player_id] = 0
		# Set oddball_mode to true for skull spawning
		oddball_mode = true
		print("Team Oddball mode enabled, spawning skull...")
		# Small delay to ensure all clients are ready
		await get_tree().create_timer(0.5).timeout
		_spawn_skull()
	elif oddball_mode and multiplayer.is_server():
		print("Oddball mode enabled, spawning skull...")
		# Small delay to ensure all clients are ready
		await get_tree().create_timer(0.5).timeout
		_spawn_skull()
	
	# Team King of the Hill initialization
	if game_mode == MODE_TEAM_KOTH and multiplayer.is_server():
		# Initialize team hill time
		team_hill_time = {TEAM_A: 0, TEAM_B: 0}
		# Set koth_mode to true for hill spawning
		koth_mode = true
		print("Team King of the Hill mode enabled, spawning hill...")
		# Small delay to ensure all clients are ready
		await get_tree().create_timer(0.5).timeout
		_spawn_hill()
	elif koth_mode and multiplayer.is_server():
		# Spawn hill if KOTH mode is enabled
		_spawn_hill()
	
	# Control cloud visibility
	_set_clouds_visibility(clouds_enabled)
	
	# Update existing players' lives for KOTH mode, FFA Slayer mode, Team Slayer mode, and Team KOTH mode
	for player in players:
		if koth_mode or game_mode == "FFA Slayer" or game_mode == "Team Slayer" or game_mode == MODE_TEAM_KOTH:
			player.lives_remaining = 999  # Effectively unlimited lives for KOTH, FFA Slayer, Team Slayer, and Team KOTH
		else:
			player.lives_remaining = player_lives
	
	# Show game UI elements now that the game has started
	_show_game_ui()
	
	print("Server config applied: Lives=%d, MaxPlayers=%d, Speed=%.1fx, Damage=%.1fx, Clouds=%s, Oddball=%s, KOTH=%s" % [player_lives, max_players, speed_multiplier, damage_multiplier, clouds_enabled, oddball_mode, koth_mode])

@rpc("authority", "call_local", "reliable")
func _apply_server_config_clients(config: Dictionary):
	"""Apply server configuration on all clients"""
	player_lives = config.get("player_lives", 3)
	max_players = config.get("max_players", 4)
	speed_multiplier = config.get("speed_multiplier", 1.0)
	damage_multiplier = config.get("damage_multiplier", 1.0)
	has_time_limit = config.get("has_time_limit", false)
	time_limit_minutes = config.get("time_limit_minutes", 10)

	clouds_enabled = config.get("clouds_enabled", true)
	oddball_mode = config.get("oddball_mode", false)
	koth_mode = config.get("koth_mode", false)
	game_mode = config.get("game_mode", "")
	game_mode_type = config.get("game_mode_type", "")
	kill_limit = config.get("kill_limit", 15)
	
	# Set initial timer value for clients
	if has_time_limit:
		time_limit_seconds = time_limit_minutes * 60.0

func _show_timer_ui():
	"""Show the countdown timer UI"""
	if multiplayer.is_server():
		_show_timer_ui_clients.rpc()

func _hide_timer_ui():
	"""Hide the countdown timer UI"""
	if multiplayer.is_server():
		_hide_timer_ui_clients.rpc()

@rpc("authority", "call_local", "reliable")
func _show_timer_ui_clients():
	"""Show the countdown timer UI on all clients"""
	if timer_ui:
		timer_ui.visible = true
		_update_timer_display()

@rpc("authority", "call_local", "reliable")
func _hide_timer_ui_clients():
	"""Hide the countdown timer UI on all clients"""
	if timer_ui:
		timer_ui.visible = false

@rpc("authority", "call_local", "reliable")
func _show_game_ui_clients():
	"""Show the game UI (scoreboard, weapon heat) on all clients"""
	_show_game_ui()

func _show_game_ui():
	"""Show the scoreboard and cooldown UI when game starts"""
	print("GameManager: Showing game UI")
	if score_ui:
		score_ui.visible = true
		print("ScoreUI shown")
	if weapon_heat_bar:
		weapon_heat_bar.visible = true
		print("WeaponHeatBar shown")
	if cooldown_label:
		cooldown_label.visible = true
		print("CooldownLabel shown")

func _hide_game_ui():
	"""Hide the scoreboard and cooldown UI when game is not active"""
	if score_ui:
		score_ui.visible = false
	if weapon_heat_bar:
		weapon_heat_bar.visible = false
	if cooldown_label:
		cooldown_label.visible = false

func _set_clouds_visibility(visible: bool):
	"""Show or hide the clouds based on server configuration"""
	# Only the server should initiate cloud visibility changes
	if multiplayer.is_server():
		_set_clouds_visibility_clients.rpc(visible)

# Called on all CLIENTS (including server) to synchronize cloud visibility
@rpc("authority", "call_local", "reliable")
func _set_clouds_visibility_clients(visible: bool):
	if clouds:
		clouds.visible = visible

# Send cloud visibility setting to a newly connected peer
func _sync_clouds_to_peer(peer_id: int):
	"""Send current cloud visibility setting to a specific peer"""
	if multiplayer.is_server():
		rpc_id(peer_id, "_set_clouds_visibility_clients", clouds_enabled)

# Send server configuration to a newly connected peer
func _sync_config_to_peer(peer_id: int):
	"""Send current server configuration to a specific peer"""
	if multiplayer.is_server():
		var config = {
			"player_lives": player_lives,
			"max_players": max_players,
			"speed_multiplier": speed_multiplier,
			"damage_multiplier": damage_multiplier,
			"has_time_limit": has_time_limit,
			"time_limit_minutes": time_limit_minutes,
	
			"clouds_enabled": clouds_enabled,
			"oddball_mode": oddball_mode,
			"koth_mode": koth_mode,
			"game_mode": game_mode,
			"game_mode_type": game_mode_type,
			"kill_limit": kill_limit
		}
		rpc_id(peer_id, "_apply_server_config_clients", config)

# Send timer state to a newly connected peer
func _sync_timer_to_peer(peer_id: int):
	"""Send current timer state to a specific peer"""
	if multiplayer.is_server():
		if has_time_limit and game_timer.time_left > 0:
			rpc_id(peer_id, "_show_timer_ui_clients")
			rpc_id(peer_id, "_update_timer_display_clients", time_limit_seconds)
		else:
			rpc_id(peer_id, "_hide_timer_ui_clients")

# Send game UI state to a newly connected peer
func _sync_game_ui_to_peer(peer_id: int):
	"""Show the game UI for a specific peer"""
	if multiplayer.is_server():
		rpc_id(peer_id, "_show_game_ui_clients")

func _update_timer_display():
	"""Update the timer display with current time remaining"""
	if multiplayer.is_server():
		_update_timer_display_clients.rpc(time_limit_seconds)

@rpc("authority", "call_local", "reliable")
func _update_timer_display_clients(seconds_remaining: float):
	"""Update the timer display on all clients"""
	# Update local timer value for clients
	time_limit_seconds = seconds_remaining
	
	if not timer_label or not has_time_limit:
		return
	
	var minutes = int(seconds_remaining) / 60
	var seconds = int(seconds_remaining) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]
	
	# Change color based on time remaining
	if seconds_remaining <= 10:
		timer_label.add_theme_color_override("font_color", Color.RED)
	elif seconds_remaining <= 60:
		timer_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)

func _on_game_timer_timeout():
	"""Handle time limit countdown"""
	if has_time_limit and time_limit_seconds > 0:
		time_limit_seconds -= 1.0
		_update_timer_display()
		
		# Warn players at certain intervals
		if time_limit_seconds == 60.0:  # 1 minute left
			print("1 minute remaining!")
		elif time_limit_seconds == 10.0:  # 10 seconds left
			print("10 seconds remaining!")
		elif time_limit_seconds <= 0:
			# Time's up - end game
			_time_limit_reached()

func _time_limit_reached():
	"""Handle when time limit is reached"""
	game_timer.stop()
	_hide_timer_ui()
	
	# Stop oddball scoring if active
	if oddball_mode:
		oddball_score_timer.stop()
	
	# Stop KOTH scoring if active
	if koth_mode:
		koth_score_timer.stop()
		hill_movement_timer.stop()
	
	if koth_mode:
		# KOTH mode: winner is player with highest hill control score
		var highest_score = -1
		var winners: Array[Player] = []
		
		for player in players:
			if player.koth_score > highest_score:
				highest_score = player.koth_score
				winners = [player]
			elif player.koth_score == highest_score:
				winners.append(player)
		
		# Handle KOTH results
		if winners.size() == 0 or highest_score == 0:
			end_game_clients.rpc("Time Limit Reached - No Winner")
		elif winners.size() == 1:
			end_game_clients.rpc(winners[0].player_name + " (King of the Hill Winner - " + str(highest_score) + " seconds)")
		else:
			# Multiple winners - tie
			var winner_names = []
			for winner in winners:
				winner_names.append(winner.player_name)
			var tie_text = "Tie Game!\n" + " & ".join(winner_names) + " tied with " + str(highest_score) + " seconds"
			end_game_clients.rpc(tie_text)
	elif oddball_mode:
		# Oddball mode: winner is player with highest oddball score
		var highest_score = -1
		var winners: Array[Player] = []
		
		for player in players:
			if player.oddball_score > highest_score:
				highest_score = player.oddball_score
				winners = [player]
			elif player.oddball_score == highest_score:
				winners.append(player)
		
		# Handle oddball results
		if winners.size() == 0 or highest_score == 0:
			end_game_clients.rpc("Time Limit Reached - No Winner")
		elif winners.size() == 1:
			end_game_clients.rpc(winners[0].player_name + " (Oddball Winner - " + str(highest_score) + " seconds)")
		else:
			# Multiple winners - tie
			var winner_names = []
			for winner in winners:
				winner_names.append(winner.player_name)
			var tie_text = "Tie Game!\n" + " & ".join(winner_names) + " tied with " + str(highest_score) + " seconds"
			end_game_clients.rpc(tie_text)
	elif game_mode == "Team Slayer":
		# Team Slayer mode: winner is team with highest kill score
		var team_a_score = team_kill_scores[0]
		var team_b_score = team_kill_scores[1]
		
		if team_a_score > team_b_score:
			end_game_clients.rpc("Team A (Time Limit Winner - " + str(team_a_score) + " kills)")
		elif team_b_score > team_a_score:
			end_game_clients.rpc("Team B (Time Limit Winner - " + str(team_b_score) + " kills)")
		else:
			# Teams tied
			end_game_clients.rpc("Tie Game!\nTeam A & Team B tied with " + str(team_a_score) + " kills")
	elif game_mode == MODE_TEAM_KOTH:
		# Team King of the Hill mode: winner is team with most hill time
		_check_team_koth_time_limit()
	else:
		# Standard mode: winner is player with highest kill score
		var highest_score = -1
		var winners: Array[Player] = []
		
		# Get all players that are still alive (have lives remaining)
		var alive_players = []
		for player in players:
			if player.lives_remaining > 0:
				alive_players.append(player)
		
		# Find highest score among alive players
		for player in alive_players:
			if player.score > highest_score:
				highest_score = player.score
				winners = [player]
			elif player.score == highest_score:
				winners.append(player)
		
		# Handle different scenarios
		if winners.size() == 0:
			end_game_clients.rpc("Time Limit Reached - No Winner")
		elif winners.size() == 1:
			end_game_clients.rpc(winners[0].player_name + " (Most Kills)")
		else:
			# Multiple winners - tie
			var winner_names = []
			for winner in winners:
				winner_names.append(winner.player_name)
			var tie_text = "Tie Game!\n" + " & ".join(winner_names) + " tie for " + _get_place_suffix(highest_score)
			end_game_clients.rpc(tie_text)

func _check_for_new_players():
	# Create health bars for any players that don't have one yet
	for player in players:
		if player.health_bar == null:
			create_health_bar_for_player(player)

func create_health_bar_for_player(player: Player):
	# Create a new health bar instance
	var health_bar = health_bar_scene.instantiate()
	
	# Add it to the main scene as a UI element
	get_tree().get_current_scene().add_child(health_bar)
	
	# Set up the health bar with the player
	health_bar.set_target_player(player)
	player.set_health_bar(health_bar)
	
	# Add to our tracking array
	health_bars.append(health_bar)

func remove_health_bar_for_player(player: Player):
	if player.health_bar != null:
		# Remove from tracking array
		health_bars.erase(player.health_bar)
		
		# Remove from scene
		player.health_bar.queue_free()
		player.health_bar = null

func get_random_position () -> Vector2:
	# Ensure players don't spawn closer than 40 px to the window edges
	var padding := 40.0
	var x = randf_range(min_x + padding, max_x - padding)
	var y = randf_range(min_y + padding, max_y - padding)
	return Vector2(x, y)

func get_team_spawn_position(team: int) -> Vector2:
	"""Get spawn position for team-based modes"""
	var padding := 40.0
	var team_players = []
	
	# Count existing players on this team
	for player in players:
		if player.team == team:
			team_players.append(player)
	
	var spawn_index = team_players.size()  # Position for the new player
	
	if team == 0:  # Team A - left half
		var x = min_x + padding + 60  # Fixed x position on left side
		var available_height = (max_y - padding) - (min_y + padding)
		var spacing = available_height / max(1, max_players / 2)  # Divide height by max team size
		var y = min_y + padding + (spawn_index + 0.5) * spacing
		y = clamp(y, min_y + padding, max_y - padding)
		return Vector2(x, y)
	else:  # Team B - right half
		var x = max_x - padding - 60  # Fixed x position on right side
		var available_height = (max_y - padding) - (min_y + padding)
		var spacing = available_height / max(1, max_players / 2)  # Divide height by max team size
		var y = min_y + padding + (spawn_index + 0.5) * spacing
		y = clamp(y, min_y + padding, max_y - padding)
		return Vector2(x, y)

func set_team_assignments(assignments: Dictionary):
	"""Set team assignments from lobby"""
	team_assignments = assignments.duplicate()
	is_team_mode = true
	
	# Broadcast to all clients
	if multiplayer.is_server():
		_sync_team_assignments.rpc(team_assignments)
	
	# Apply team assignments to existing players
	for player in players:
		if team_assignments.has(player.player_id):
			player.team = team_assignments[player.player_id]
		else:
			# Auto-assign to team with fewer players
			player.team = _auto_assign_team(player.player_id)

func _auto_assign_team(player_id: int) -> int:
	"""Auto-assign player to team with fewer members"""
	var team_a_count = 0
	var team_b_count = 0
	
	for id in team_assignments:
		if team_assignments[id] == 0:
			team_a_count += 1
		else:
			team_b_count += 1
	
	var assigned_team = 0 if team_a_count <= team_b_count else 1
	team_assignments[player_id] = assigned_team
	return assigned_team

@rpc("authority", "call_local", "reliable")
func _sync_team_assignments(assignments: Dictionary):
	"""Sync team assignments to all clients"""
	team_assignments = assignments.duplicate()
	is_team_mode = assignments.size() > 0
	
	# Apply to existing players
	for player in players:
		if team_assignments.has(player.player_id):
			player.team = team_assignments[player.player_id]

func _sync_team_to_peer(peer_id: int):
	"""Sync team assignments to a specific peer"""
	if multiplayer.is_server() and is_team_mode:
		rpc_id(peer_id, "_sync_team_assignments", team_assignments)

# called when a player is killed (but still has lives)
func on_player_die (player_id : int, attacker_id : int):
	var player : Player = get_player(player_id)
	var attacker : Player = get_player(attacker_id)
	
	# Team Oddball kill handling
	if game_mode == MODE_TEAM_ODDBALL:
		_handle_team_oddball_kill(player, attacker)
	elif game_mode == MODE_TEAM_KOTH:
		_handle_team_koth_kill(player, attacker)
	elif game_mode == "Team Slayer":
		if attacker.team != player.team:
			# Enemy kill: +1 to attacker score and team score
			attacker.increase_score(1)
			_update_team_score(attacker.team, 1)
		else:
			# Friendly fire: -1 to attacker score (minimum -1) and team score
			attacker.score -= 1
			if attacker.score < -1:
				attacker.score = -1
			_update_team_score(attacker.team, -1)
	else:
		# Standard behavior for other modes
		attacker.increase_score(1)
	
	# Sync kills count to all clients
	_sync_score.rpc(attacker_id, attacker.score)
	
	# Sync deaths count to all clients
	_sync_deaths.rpc(player_id, player.deaths)
	
	# Check for kill limit win condition in FFA Slayer mode
	if game_mode == "FFA Slayer" and attacker.score >= kill_limit:
		end_game_clients.rpc(attacker.player_name + " (FFA Slayer Winner - " + str(kill_limit) + " kills)")
		return
	
	# No automatic win based on kill count for other modes - only check for last player standing

# called when a player is eliminated (no lives remaining)
func on_player_eliminated (player_id : int, attacker_id : int):
	var player : Player = get_player(player_id)
	var attacker : Player = get_player(attacker_id)
	
	# Team modes logic
	if game_mode == "Team Slayer":
		if attacker.team != player.team:
			# Enemy kill: +1 to attacker score and team score
			attacker.increase_score(1)
			_update_team_score(attacker.team, 1)
		else:
			# Friendly fire: -1 to attacker score (minimum -1) and team score
			attacker.score -= 1
			if attacker.score < -1:
				attacker.score = -1
			_update_team_score(attacker.team, -1)
	elif game_mode == MODE_TEAM_KOTH:
		_handle_team_koth_kill(player, attacker)
	else:
		# Standard behavior for other modes
		attacker.increase_score(1)
	
	# Sync kills count to all clients
	_sync_score.rpc(attacker_id, attacker.score)
	
	# Sync deaths count to all clients
	_sync_deaths.rpc(player_id, player.deaths)
	
	# Check for kill limit win condition in FFA Slayer mode
	if game_mode == "FFA Slayer" and attacker.score >= kill_limit:
		end_game_clients.rpc(attacker.player_name + " (FFA Slayer Winner - " + str(kill_limit) + " kills)")
		return
	
	print("Player %s eliminated! (Lives remaining: %d)" % [player.player_name, player.lives_remaining])
	
	# Don't check for last player standing in FFA Slayer mode or Team Slayer mode (unlimited lives)
	if game_mode == "FFA Slayer" or game_mode == "Team Slayer":
		return
	
	# Check if only one player remains alive
	var alive_players = []
	for p in players:
		if p.lives_remaining > 0:
			alive_players.append(p)
	
	if alive_players.size() <= 1:
		if alive_players.size() == 1:
			# Last player standing wins
			var winner_message = "One player remains.\n" + alive_players[0].player_name + " wins!"
			end_game_clients.rpc(winner_message)
		else:
			# Everyone eliminated (shouldn't happen but just in case)
			end_game_clients.rpc("No Survivors")

# finds the player belonging to the player_id
# and returns them
func get_player (player_id : int) -> Player:
	for player in players:
		if player.player_id == player_id:
			return player
	
	return null

# called when the "Play Again" button is pressed
func reset_game():
	for player in players:
		player.respawn()
		# Reset ALL player statistics
		player.score = 0
		player.oddball_score = 0
		player.koth_score = 0
		player.deaths = 0
		# Reset health to full
		player.cur_hp = player.max_hp
		# Reset weapon heat to zero
		player.cur_weapon_heat = 0.0
		# Reset lives to configured amount (use 999 for unlimited in KOTH mode, FFA Slayer mode, Team Slayer mode, and Team KOTH mode)
		if koth_mode or game_mode == "FFA Slayer" or game_mode == "Team Slayer" or game_mode == MODE_TEAM_KOTH:
			player.lives_remaining = 999  # Effectively unlimited lives for KOTH, FFA Slayer, Team Slayer, and Team KOTH
		else:
			player.lives_remaining = player_lives
		
		# Sync ALL player statistics to all clients to update scoreboard UI
		if multiplayer.is_server():
			player._sync_health.rpc(player.cur_hp)
			player._sync_weapon_heat.rpc(player.cur_weapon_heat)
			# Sync all scores to update scoreboard UI
			_sync_score.rpc(player.player_id, player.score)  # kills/score
			_sync_deaths.rpc(player.player_id, player.deaths)  # deaths
			_sync_oddball_score.rpc(player.player_id, player.oddball_score)  # oddball score
			_sync_koth_score.rpc(player.player_id, player.koth_score)  # koth score
	
	# Reset team kill scores
	team_kill_scores = {0:0, 1:0}
	
	# Reset team hill time for Team KOTH mode
	team_hill_time = {TEAM_A: 0, TEAM_B: 0}
	
	# Sync team score resets to all clients
	if multiplayer.is_server() and is_team_mode:
		_sync_team_score.rpc(0, 0)
		_sync_team_score.rpc(1, 0)
		# Sync team hill time reset
		if game_mode == MODE_TEAM_KOTH:
			_sync_team_hill_time.rpc(team_hill_time)
	
	# Reset time limit
	if has_time_limit:
		time_limit_seconds = time_limit_minutes * 60.0
		game_timer.start()
		_show_timer_ui()
	else:
		_hide_timer_ui()
	

	
	# Reset oddball mode
	if oddball_mode and multiplayer.is_server():
		# Stop scoring timer
		oddball_score_timer.stop()
		skull_holder = null
		# Remove any existing skull
		if current_skull != null and is_instance_valid(current_skull):
			current_skull.queue_free()
		current_skull = null
		# Spawn a new skull immediately
		_spawn_skull()
	
	# Reset KOTH mode
	if koth_mode and multiplayer.is_server():
		# Stop timers
		koth_score_timer.stop()
		hill_movement_timer.stop()
		# Remove any existing hill
		if current_hill != null and is_instance_valid(current_hill):
			current_hill.queue_free()
		current_hill = null
		# Spawn a new hill immediately
		_spawn_hill()
	
	reset_game_clients.rpc()

# called when the game resets on all CLIENTS
@rpc("authority", "call_local", "reliable")
func reset_game_clients ():
	# Clean up any dynamically created buttons from results screen
	if end_screen.has_node("ButtonContainer"):
		end_screen.get_node("ButtonContainer").queue_free()
	
	end_screen.visible = false
	_show_game_ui()  # Show UI again when game resets

# called when the game ends on all CLIENTS
@rpc("authority", "call_local", "reliable")
func end_game_clients (winner_name : String):
	end_screen.visible = true
	# Check if the message already contains "wins!" to avoid duplication
	if winner_name.contains("wins!"):
		end_screen_winner_text.text = winner_name
	else:
		end_screen_winner_text.text = str(winner_name, " wins!")
	end_screen_button.visible = false

	# Initialize countdown
	lobby_countdown_seconds = 4
	if lobby_countdown_label:
		lobby_countdown_label.visible = true
		lobby_countdown_label.text = "Returning to lobby in %d..." % lobby_countdown_seconds

	# Start countdown timer
	lobby_countdown_timer.start()

func _on_return_lobby_pressed():
	if multiplayer.is_server():
		_return_to_lobby()

# Return to lobby function - server only
func _return_to_lobby():
	if not multiplayer.is_server():
		print("_return_to_lobby can only be called on server")
		return

	# Stop all timers
	oddball_score_timer.stop()
	hill_movement_timer.stop()
	koth_score_timer.stop()
	game_timer.stop()
	lobby_countdown_timer.stop()

	# Delete spawned powerups and objects
	if current_skull != null and is_instance_valid(current_skull):
		current_skull.queue_free()
		current_skull = null
	if current_hill != null and is_instance_valid(current_hill):
		current_hill.queue_free()
		current_hill = null

	# Get NetworkManager and return to lobby BEFORE any scene changes
	var network_manager = get_node("/root/Main/Network")
	if network_manager:
		network_manager.return_to_lobby(game_mode_type, network_manager.get_server_config(), team_assignments)
		print("Returning to lobby...")
	else:
		print("Error: Could not find NetworkManager")
func _get_place_suffix(score: int) -> String:
	"""Convert a score to a place description (first, second, third, etc.)"""
	if score == 0:
		return "last place"
	elif score == 1:
		return "first"
	elif score == 2:
		return "second"
	elif score == 3:
		return "third"
	else:
		return str(score) + "th place"







# ============================================================
# ODDBALL MODE FUNCTIONS
# ============================================================

func _spawn_skull():
	"""Spawn the skull for oddball mode"""
	if not multiplayer.is_server() or not oddball_mode:
		return
	
	if current_skull != null and is_instance_valid(current_skull):
		return
	
	print("[Skull] Server spawning skull...")
	
	current_skull = skull_scene.instantiate()
	current_skull.position = Vector2(0, 0)  # Spawn at center of map
	current_skull.skull_picked_up.connect(_on_skull_picked_up)
	current_skull.skull_dropped.connect(_on_skull_dropped)
	
	get_tree().get_current_scene().get_node("Network/SpawnedNodes").add_child(current_skull, true)
	
	# Inform all clients to spawn a matching skull locally
	print("[Skull] Calling RPC to spawn skull on clients at position: " + str(current_skull.position))
	rpc("_spawn_skull_clients", current_skull.position)
	
	print("Skull spawned at position: " + str(current_skull.position))

func _on_skull_picked_up(player: Player):
	"""Called when a player picks up the skull"""
	skull_holder = player
	oddball_score_timer.start()
	print("Skull picked up by: " + player.player_name)

func _on_skull_dropped():
	"""Called when the skull is dropped"""
	skull_holder = null
	oddball_score_timer.stop()
	print("Skull dropped!")

func _on_oddball_score_timer():
	"""Give 1 point every second to skull holder"""
	if skull_holder and is_instance_valid(skull_holder):
		skull_holder.oddball_score += 1
		
		# Sync score to all clients
		_sync_oddball_score.rpc(skull_holder.player_id, skull_holder.oddball_score)
		
		# Check for win condition
		if skull_holder.oddball_score >= oddball_win_score:
			_oddball_win(skull_holder)

func _oddball_win(winner: Player):
	"""Handle oddball mode win"""
	oddball_score_timer.stop()
	end_game_clients.rpc(winner.player_name + " (Oddball Winner)")

@rpc("authority", "call_local", "reliable")
func _spawn_skull_clients(position: Vector2):
	"""Create a skull on non-server peers so everyone can see it"""
	print("[Skull] _spawn_skull_clients called with position: " + str(position))
	
	# Avoid duplicating the skull on the server
	if multiplayer.is_server():
		print("[Skull] Client spawn ignored on server")
		return

	# Safety: ensure we don't already have a skull
	for child in get_tree().get_current_scene().get_node("Network/SpawnedNodes").get_children():
		if child is Skull:
			print("[Skull] Client already has a skull, skipping spawn")
			return

	print("[Skull] Client spawning skull at position: " + str(position))
	var skull = skull_scene.instantiate()
	skull.position = position
	get_tree().get_current_scene().get_node("Network/SpawnedNodes").add_child(skull)
	print("[Skull] Client skull spawned successfully")

@rpc("authority", "call_local", "reliable")
func _sync_oddball_score(player_id: int, score: int):
	"""Sync oddball score to all clients"""
	var player = get_player(player_id)
	if player:
		player.oddball_score = score

func drop_skull_on_death(player: Player, death_position: Vector2 = Vector2.ZERO):
	"""Drop skull when player dies if they're holding it"""
	print("[Skull] drop_skull_on_death called for player: " + player.player_name)
	print("[Skull] oddball_mode: " + str(oddball_mode) + ", game_mode: " + str(game_mode))
	print("[Skull] skull_holder: " + (skull_holder.player_name if skull_holder else "null"))
	print("[Skull] current_skull valid: " + str(current_skull != null and is_instance_valid(current_skull)))
	
	# Check for both regular Oddball and Team Oddball modes
	if (oddball_mode or game_mode == MODE_TEAM_ODDBALL) and skull_holder == player and current_skull:
		print("[Skull] Player " + player.player_name + " died while holding skull, dropping at death position")
		# Use death position if provided, otherwise use current skull position
		if death_position != Vector2.ZERO:
			current_skull.drop_skull_at_position(death_position)
		else:
			current_skull.drop_skull()
	else:
		print("[Skull] Conditions not met for skull drop - not dropping skull")

# Send skull to a single newly-connected peer (called by NetworkManager)
func _sync_skull_to_peer(peer_id: int):
	"""Send current skull state to a specific peer"""
	if multiplayer.is_server() and oddball_mode and current_skull and is_instance_valid(current_skull):
		rpc_id(peer_id, "_spawn_skull_clients", current_skull.position)
	
	# Also sync all players' oddball scores to the new peer
	if multiplayer.is_server() and oddball_mode:
		for player in players:
			if player.oddball_score > 0:
				rpc_id(peer_id, "_sync_oddball_score", player.player_id, player.oddball_score)

# ============================================================
# KING OF THE HILL MODE FUNCTIONS
# ============================================================

func _spawn_hill():
	"""Spawn the hill for KOTH mode"""
	if not multiplayer.is_server() or not koth_mode:
		return
	
	if current_hill != null and is_instance_valid(current_hill):
		return
	
	print("[Hill] Server spawning hill...")
	
	current_hill = hill_scene.instantiate()
	current_hill.position = Vector2(0, 0)  # Spawn at center of map
	current_hill.player_entered_hill.connect(_on_player_entered_hill)
	current_hill.player_exited_hill.connect(_on_player_exited_hill)
	
	get_tree().get_current_scene().get_node("Network/SpawnedNodes").add_child(current_hill, true)
	
	# Start hill movement timer
	hill_movement_timer.start()
	
	# Inform all clients to spawn a matching hill locally
	print("[Hill] Calling RPC to spawn hill on clients at position: " + str(current_hill.position))
	rpc("_spawn_hill_clients", current_hill.position)
	
	print("Hill spawned at position: " + str(current_hill.position))

func _on_player_entered_hill(player: Player):
	"""Called when a player enters the hill"""
	print("Player " + player.player_name + " entered the hill")
	
	# Start KOTH scoring timer if this is the first player in the hill
	if current_hill.get_players_in_hill().size() == 1:
		koth_score_timer.start()

func _on_player_exited_hill(player: Player):
	"""Called when a player exits the hill"""
	print("Player " + player.player_name + " exited the hill")
	
	# Stop KOTH scoring timer if no players are in the hill
	if current_hill.get_players_in_hill().size() == 0:
		koth_score_timer.stop()

func _on_hill_movement_timer():
	"""Move hill to a random location every 30 seconds"""
	if current_hill and is_instance_valid(current_hill):
		var new_position = _get_random_hill_position()
		current_hill.move_to_position(new_position)
		
		# Sync hill position to all clients
		_move_hill_clients.rpc(new_position)
		
		print("Hill moved to position: " + str(new_position))

func _get_random_hill_position() -> Vector2:
	"""Get a random position for the hill that keeps it fully visible"""
	var padding = 100.0  # Extra padding to ensure full circle is visible
	var x = randf_range(min_x + padding, max_x - padding)
	var y = randf_range(min_y + padding, max_y - padding)
	return Vector2(x, y)

func _on_koth_score_timer():
	"""Give 1 point every second to all players in the hill"""
	if current_hill and is_instance_valid(current_hill):
		var players_in_hill = current_hill.get_players_in_hill()
		
		# Handle Team King of the Hill mode
		if game_mode == MODE_TEAM_KOTH:
			_handle_team_koth_scoring(players_in_hill)
		else:
			# Regular KOTH mode
			for player in players_in_hill:
				if is_instance_valid(player):
					player.koth_score += 1
					
					# Sync score to all clients
					_sync_koth_score.rpc(player.player_id, player.koth_score)
					
					# Check for win condition
					if player.koth_score >= koth_win_score:
						_koth_win(player)
						return

func _handle_team_koth_scoring(players_in_hill: Array):
	"""Handle Team King of the Hill scoring"""
	# Count which teams have players in hill
	var teams_in_hill = {}
	for player in players_in_hill:
		if is_instance_valid(player) and player.player_id in team_assignments:
			var team = team_assignments[player.player_id]
			teams_in_hill[team] = true
	
	# Award points only if exactly one team controls the hill
	if teams_in_hill.size() == 1:
		var controlling_team = teams_in_hill.keys()[0]
		team_hill_time[controlling_team] += 1
		
		# Sync team hill time to all clients
		_sync_team_hill_time.rpc(team_hill_time)
		
		# Check for team win condition
		if team_hill_time[controlling_team] >= team_koth_win_score:
			_team_koth_win(controlling_team)

func _team_koth_win(winning_team: int):
	"""Handle Team King of the Hill win"""
	koth_score_timer.stop()
	hill_movement_timer.stop()
	var team_name = "Team A" if winning_team == TEAM_A else "Team B"
	end_game_clients.rpc(team_name + " (Team King of the Hill Winner)")

func _koth_win(winner: Player):
	"""Handle KOTH mode win"""
	koth_score_timer.stop()
	hill_movement_timer.stop()
	end_game_clients.rpc(winner.player_name + " (King of the Hill Winner)")

@rpc("authority", "call_local", "reliable")
func _spawn_hill_clients(position: Vector2):
	"""Create a hill on non-server peers so everyone can see it"""
	print("[Hill] _spawn_hill_clients called with position: " + str(position))
	
	# Avoid duplicating the hill on the server
	if multiplayer.is_server():
		print("[Hill] Client spawn ignored on server")
		return

	# Safety: ensure we don't already have a hill
	for child in get_tree().get_current_scene().get_node("Network/SpawnedNodes").get_children():
		if child is Hill:
			print("[Hill] Client already has a hill, skipping spawn")
			return

	print("[Hill] Client spawning hill at position: " + str(position))
	var hill = hill_scene.instantiate()
	hill.position = position
	get_tree().get_current_scene().get_node("Network/SpawnedNodes").add_child(hill)
	print("[Hill] Client hill spawned successfully")

@rpc("authority", "call_local", "reliable")
func _move_hill_clients(position: Vector2):
	"""Move hill to new position on all clients"""
	for child in get_tree().get_current_scene().get_node("Network/SpawnedNodes").get_children():
		if child is Hill:
			child.move_to_position(position)
			print("[Hill] Client hill moved to position: " + str(position))
			break

@rpc("authority", "call_local", "reliable")
func _sync_koth_score(player_id: int, score: int):
	"""Sync KOTH score to all clients"""
	var player = get_player(player_id)
	if player:
		player.koth_score = score

@rpc("authority", "call_local", "reliable")
func _sync_team_hill_time(hill_times: Dictionary):
	"""Sync team hill times to all clients"""
	team_hill_time = hill_times

@rpc("authority", "call_local", "reliable")
func _sync_deaths(player_id: int, deaths: int):
	"""Sync deaths count to all clients"""
	var player = get_player(player_id)
	if player:
		player.deaths = deaths

@rpc("authority", "call_local", "reliable")
func _sync_score(player_id: int, score: int):
	"""Sync score/kills count to all clients"""
	var player = get_player(player_id)
	if player:
		player.score = score

@rpc("authority", "call_local", "reliable")
func _sync_team_score(team: int, score: int):
	"""Sync team score to all clients"""
	if team_kill_scores.has(team):
		team_kill_scores[team] = score
		print("Team %d score synced: %d" % [team, score])

# Send hill to a single newly-connected peer (called by NetworkManager)
func _sync_hill_to_peer(peer_id: int):
	"""Send current hill state to a specific peer"""
	if multiplayer.is_server() and koth_mode and current_hill and is_instance_valid(current_hill):
		rpc_id(peer_id, "_spawn_hill_clients", current_hill.position)
	
	# Also sync all players' KOTH scores to the new peer
	if multiplayer.is_server() and koth_mode:
		for player in players:
			if player.koth_score > 0:
				rpc_id(peer_id, "_sync_koth_score", player.player_id, player.koth_score)

# Send deaths to a single newly-connected peer (called by NetworkManager)
func _sync_deaths_to_peer(peer_id: int):
	"""Send current deaths count to a specific peer"""
	if multiplayer.is_server():
		for player in players:
			if player.deaths > 0:
				rpc_id(peer_id, "_sync_deaths", player.player_id, player.deaths)

# Send scores to a single newly-connected peer (called by NetworkManager)
func _sync_score_to_peer(peer_id: int):
	"""Send current score/kills count to a specific peer"""
	if multiplayer.is_server():
		for player in players:
			if player.score > 0:
				rpc_id(peer_id, "_sync_score", player.player_id, player.score)
		
		# Also sync team scores to the new peer if in team mode
		if is_team_mode:
			for team in team_kill_scores:
				if team_kill_scores[team] > 0:
					rpc_id(peer_id, "_sync_team_score", team, team_kill_scores[team])

func _update_team_score(team: int, delta: int):
	"""Update team kill score and check for win condition (> 30)"""
	if not is_team_mode or not team_kill_scores.has(team):
		return
	
	# Update team score (allow negatives)
	team_kill_scores[team] += delta
	
	# Ensure score doesn't go below 0
	if team_kill_scores[team] < 0:
		team_kill_scores[team] = 0
	
	# Sync team score to all clients
	if multiplayer.is_server():
		_sync_team_score.rpc(team, team_kill_scores[team])
	
	# Check for win condition (> 30)
	if team_kill_scores[team] >= 30:
		var team_name = "Team A" if team == 0 else "Team B"
		end_game_clients.rpc(team_name + " (Team Victory - " + str(team_kill_scores[team]) + " kills)")

# ============================================================
# TEAM ODDBALL MODE FUNCTIONS
# ============================================================

func _handle_team_oddball_kill(victim: Player, killer: Player):
	"""Handle kill counting for Team Oddball mode"""
	# Ensure both players are tracked in kill dictionary
	if not player_kills.has(victim.player_id):
		player_kills[victim.player_id] = 0
	if killer and not player_kills.has(killer.player_id):
		player_kills[killer.player_id] = 0
	
	if killer and killer.team != victim.team:
		# Enemy kill: increment killer's kill count
		player_kills[killer.player_id] += 1
	elif killer:
		# Friendly fire: decrement but don't go below 0
		player_kills[killer.player_id] = max(0, player_kills[killer.player_id] - 1)

func _check_team_oddball_win():
	"""Check if any team has reached 100 seconds of skull time"""
	for team in team_skull_time:
		if team_skull_time[team] >= 100.0:
			_end_team_oddball_match(team)

func _check_team_oddball_time_limit():
	"""Check Team Oddball time limit (300s) and determine winner"""
	if time_limit_seconds <= 0.0:
		# Determine winner based on skull time, tiebreaker by kills
		if team_skull_time[TEAM_A] > team_skull_time[TEAM_B]:
			_end_team_oddball_match(TEAM_A)
		elif team_skull_time[TEAM_B] > team_skull_time[TEAM_A]:
			_end_team_oddball_match(TEAM_B)
		else:
			# Tie on skull time, tiebreaker by team kills
			var team_a_kills = 0
			var team_b_kills = 0
			
			for player_id in player_kills:
				if team_assignments.has(player_id):
					if team_assignments[player_id] == TEAM_A:
						team_a_kills += player_kills[player_id]
					elif team_assignments[player_id] == TEAM_B:
						team_b_kills += player_kills[player_id]
			
			if team_a_kills > team_b_kills:
				_end_team_oddball_match(TEAM_A)
			elif team_b_kills > team_a_kills:
				_end_team_oddball_match(TEAM_B)
			else:
				# Complete tie, declare draw
				end_game_clients.rpc("Draw! Both teams tied on skull time and kills.")

func _end_team_oddball_match(winning_team: int):
	"""End Team Oddball match with specified winning team"""
	var team_name = "Team A" if winning_team == TEAM_A else "Team B"
	var skull_time = int(team_skull_time[winning_team])
	
	# Create results data for Team Oddball
	var results_data = {
		"game_mode": "Team Oddball",
		"winning_team": winning_team,
		"team_name": team_name,
		"team_a_skull_time": int(team_skull_time[TEAM_A]),
		"team_b_skull_time": int(team_skull_time[TEAM_B]),
		"individual_stats": []
	}
	
	# Collect individual player statistics
	for player in players:
		var player_stats = {
			"player_name": player.player_name,
			"player_id": player.player_id,
			"team": player.team,
			"kills": player_kills.get(player.player_id, 0),
			"deaths": player.deaths
		}
		results_data.individual_stats.append(player_stats)
	
	# Announce the team oddball winner via RPC
	announce_team_oddball_winner.rpc(winning_team)
	
	# End the game with results data
	end_game_with_results.rpc(results_data)

@rpc("authority", "call_local", "reliable")
func update_team_oddball_time(team: int, time: float):
	"""Update team skull time on all clients"""
	team_skull_time[team] = time

@rpc("authority", "call_local", "reliable")
func announce_team_oddball_winner(team_id: int):
	"""Announce Team Oddball winner to all clients"""
	var team_name = "Team A" if team_id == TEAM_A else "Team B"
	var skull_time = int(team_skull_time[team_id])
	print("[Team Oddball] " + team_name + " wins with " + str(skull_time) + " seconds of skull time!")

# Enhanced results screen for Team Oddball and other modes
@rpc("authority", "call_local", "reliable")
func end_game_with_results(results_data: Dictionary):
	"""End game and display detailed results screen"""
	_hide_game_ui()  # Hide game UI
	_display_results_screen(results_data)

func _display_results_screen(results_data: Dictionary):
	"""Display detailed results screen with team and individual statistics"""
	end_screen.visible = true
	
	# Clear existing winner text and replace with detailed results
	if results_data.game_mode == "Team Oddball":
		# Create the winner text
		var winner_text = "Team Oddball Winners: " + results_data.team_name + "\n"
		winner_text += "Team A: " + str(results_data.team_a_skull_time) + "s | "
		winner_text += "Team B: " + str(results_data.team_b_skull_time) + "s\n\n"
		winner_text += "Individual Kill Stats:\n"
		
		# Sort players by team and then by kills
		var team_a_players = []
		var team_b_players = []
		
		for player_stat in results_data.individual_stats:
			if player_stat.team == 0:
				team_a_players.append(player_stat)
			else:
				team_b_players.append(player_stat)
		
		# Sort by kills (descending)
		team_a_players.sort_custom(func(a, b): return a.kills > b.kills)
		team_b_players.sort_custom(func(a, b): return a.kills > b.kills)
		
		# Add Team A stats
		winner_text += "Team A:\n"
		for player in team_a_players:
			winner_text += "  " + player.player_name + ": " + str(player.kills) + " kills, " + str(player.deaths) + " deaths\n"
		
		# Add Team B stats
		winner_text += "Team B:\n"
		for player in team_b_players:
			winner_text += "  " + player.player_name + ": " + str(player.kills) + " kills, " + str(player.deaths) + " deaths\n"
		
		end_screen_winner_text.text = winner_text
	
	# Hide the play again button and show countdown
	end_screen_button.visible = false
	
	# Add "Play again" and "Back to lobby" functionality
	if not end_screen.has_node("ButtonContainer"):
		var button_container = HBoxContainer.new()
		button_container.name = "ButtonContainer"
		button_container.position = Vector2(250, 350)
		button_container.add_theme_constant_override("separation", 20)
		
		var play_again_btn = Button.new()
		play_again_btn.text = "Play Again"
		play_again_btn.custom_minimum_size = Vector2(120, 40)
		play_again_btn.pressed.connect(_on_play_again_pressed)
		
		var back_to_lobby_btn = Button.new()
		back_to_lobby_btn.text = "Back to Lobby"
		back_to_lobby_btn.custom_minimum_size = Vector2(120, 40)
		back_to_lobby_btn.pressed.connect(_on_back_to_lobby_pressed)
		
		button_container.add_child(play_again_btn)
		button_container.add_child(back_to_lobby_btn)
		end_screen.add_child(button_container)
	
	# Initialize countdown
	lobby_countdown_seconds = 4
	if lobby_countdown_label:
		lobby_countdown_label.visible = true
		lobby_countdown_label.text = "Returning to lobby in %d..." % lobby_countdown_seconds
	
	# Start countdown timer
	lobby_countdown_timer.start()

func _on_play_again_pressed():
	"""Handle Play Again button press"""
	if multiplayer.is_server():
		reset_game()

func _on_back_to_lobby_pressed():
	"""Handle Back to Lobby button press"""
	if multiplayer.is_server():
		_return_to_lobby()

func _on_lobby_countdown_tick():
	lobby_countdown_seconds -= 1
	if lobby_countdown_label and lobby_countdown_seconds >= 0:
		lobby_countdown_label.text = "Returning to lobby in %d..." % lobby_countdown_seconds
	if lobby_countdown_seconds <= 0:
		lobby_countdown_timer.stop()
		if multiplayer.is_server():
			_return_to_lobby()  # existing function handles sending everyone back

# ============================================================
# TEAM KING OF THE HILL MODE FUNCTIONS
# ============================================================

func _handle_team_koth_kill(victim: Player, killer: Player):
	"""Handle kill counting for Team King of the Hill mode"""
	if killer and killer.team != victim.team:
		# Enemy kill: +1 to killer's score
		killer.increase_score(1)
	elif killer:
		# Friendly fire: -1 to killer's score (minimum -1)
		killer.score -= 1
		if killer.score < -1:
			killer.score = -1

func _check_team_koth_time_limit():
	"""Check Team KOTH time limit and determine winner based on hill time"""
	if time_limit_seconds <= 0.0:
		# Determine winner based on hill time
		if team_hill_time[TEAM_A] > team_hill_time[TEAM_B]:
			_team_koth_win(TEAM_A)
		elif team_hill_time[TEAM_B] > team_hill_time[TEAM_A]:
			_team_koth_win(TEAM_B)
		else:
			# Complete tie on hill time
			end_game_clients.rpc("Draw! Both teams tied on hill control time.")
