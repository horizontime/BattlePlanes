extends Node

var players : Array[Player]
var local_player : Player

# Game configuration settings
var player_lives : int = 3
var max_players : int = 4
var speed_multiplier : float = 1.0
var damage_multiplier : float = 1.0
var has_time_limit : bool = false
var time_limit_minutes : int = 10
var hearts_enabled : bool = false
var clouds_enabled : bool = true
var oddball_mode : bool = false
var koth_mode : bool = false
var game_mode : String = ""
var kill_limit : int = 15

# Heart powerup management
var heart_scene = preload("res://Scenes/Heart.tscn")
var current_heart : Heart = null
var heart_spawn_timer : Timer

# Oddball mode management
var skull_scene = preload("res://Scenes/Skull.tscn")
var current_skull : Skull = null
var skull_holder : Player = null
var oddball_score_timer : Timer
var oddball_win_score : int = 60

# KOTH mode management
var hill_scene = preload("res://Scenes/Hill.tscn")
var current_hill : Hill = null
var hill_movement_timer : Timer
var koth_score_timer : Timer
var koth_win_score : int = 60

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
	
	# Create heart spawn timer
	heart_spawn_timer = Timer.new()
	heart_spawn_timer.wait_time = 30.0  # 30 seconds
	heart_spawn_timer.one_shot = true
	heart_spawn_timer.timeout.connect(_spawn_heart)
	add_child(heart_spawn_timer)
	
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

func apply_server_config(config: Dictionary):
	"""Apply server configuration settings to the game"""
	player_lives = config.get("player_lives", 3)
	max_players = config.get("max_players", 4)
	speed_multiplier = config.get("speed_multiplier", 1.0)
	damage_multiplier = config.get("damage_multiplier", 1.0)
	has_time_limit = config.get("has_time_limit", false)
	time_limit_minutes = config.get("time_limit_minutes", 10)
	hearts_enabled = config.get("hearts_enabled", false)
	clouds_enabled = config.get("clouds_enabled", true)
	oddball_mode = config.get("oddball_mode", false)
	koth_mode = config.get("koth_mode", false)
	game_mode = config.get("game_mode", "")
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
	
	# Spawn initial heart if enabled
	if hearts_enabled and multiplayer.is_server():
		_spawn_heart()
	
	# Spawn skull if oddball mode is enabled
	if oddball_mode and multiplayer.is_server():
		print("Oddball mode enabled, spawning skull...")
		# Small delay to ensure all clients are ready
		await get_tree().create_timer(0.5).timeout
		_spawn_skull()
	
	# Spawn hill if KOTH mode is enabled
	if koth_mode and multiplayer.is_server():
		_spawn_hill()
	
	# Control cloud visibility
	_set_clouds_visibility(clouds_enabled)
	
	# Update existing players' lives for KOTH mode and FFA Slayer mode
	for player in players:
		if koth_mode or game_mode == "FFA Slayer":
			player.lives_remaining = 999  # Effectively unlimited lives for KOTH and FFA Slayer
		else:
			player.lives_remaining = player_lives
	
	# Show game UI elements now that the game has started
	_show_game_ui()
	
	print("Server config applied: Lives=%d, MaxPlayers=%d, Speed=%.1fx, Damage=%.1fx, Hearts=%s, Clouds=%s, Oddball=%s, KOTH=%s" % [player_lives, max_players, speed_multiplier, damage_multiplier, hearts_enabled, clouds_enabled, oddball_mode, koth_mode])

@rpc("authority", "call_local", "reliable")
func _apply_server_config_clients(config: Dictionary):
	"""Apply server configuration on all clients"""
	player_lives = config.get("player_lives", 3)
	max_players = config.get("max_players", 4)
	speed_multiplier = config.get("speed_multiplier", 1.0)
	damage_multiplier = config.get("damage_multiplier", 1.0)
	has_time_limit = config.get("has_time_limit", false)
	time_limit_minutes = config.get("time_limit_minutes", 10)
	hearts_enabled = config.get("hearts_enabled", false)
	clouds_enabled = config.get("clouds_enabled", true)
	oddball_mode = config.get("oddball_mode", false)
	koth_mode = config.get("koth_mode", false)
	game_mode = config.get("game_mode", "")
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
			"hearts_enabled": hearts_enabled,
			"clouds_enabled": clouds_enabled,
			"oddball_mode": oddball_mode,
			"koth_mode": koth_mode,
			"game_mode": game_mode,
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

# called when a player is killed (but still has lives)
func on_player_die (player_id : int, attacker_id : int):
	var player : Player = get_player(player_id)
	var attacker : Player = get_player(attacker_id)
	
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
	
	# Don't check for last player standing in FFA Slayer mode (since it has unlimited lives)
	if game_mode == "FFA Slayer":
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
		player.score = 0
		player.oddball_score = 0
		player.koth_score = 0
		player.deaths = 0
		# Reset lives to configured amount (use 999 for unlimited in KOTH mode and FFA Slayer mode)
		if koth_mode or game_mode == "FFA Slayer":
			player.lives_remaining = 999  # Effectively unlimited lives for KOTH and FFA Slayer
		else:
			player.lives_remaining = player_lives
	
	# Reset time limit
	if has_time_limit:
		time_limit_seconds = time_limit_minutes * 60.0
		game_timer.start()
		_show_timer_ui()
	else:
		_hide_timer_ui()
	
	# Reset heart spawning
	if hearts_enabled and multiplayer.is_server():
		# Remove any existing heart
		if current_heart != null and is_instance_valid(current_heart):
			current_heart.queue_free()
		current_heart = null
		heart_spawn_timer.stop()
		# Spawn a new heart immediately
		_spawn_heart()
	
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
	end_screen_button.visible = multiplayer.is_server()

func _on_play_again_button_pressed():
	reset_game()

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

func _spawn_heart():
	"""Spawn a heart powerup at a random location"""
	# Only spawn on server and if hearts are enabled
	if not multiplayer.is_server() or not hearts_enabled:
		print("[Heart] _spawn_heart called but not server or hearts disabled")
		return
	
	# Don't spawn if there's already a heart on the map
	if current_heart != null and is_instance_valid(current_heart):
		print("[Heart] _spawn_heart called but heart already exists")
		return
	
	print("[Heart] Server spawning new heart...")
	
	# Create and position the heart (server side)
	current_heart = heart_scene.instantiate()
	current_heart.position = _get_random_heart_position()
	
	# Add to the spawned nodes (networked)
	get_tree().get_current_scene().get_node("Network/SpawnedNodes").add_child(current_heart, true)

	# Inform all clients to spawn a matching heart locally
	print("[Heart] Calling RPC to spawn heart on clients at position: " + str(current_heart.position))
	rpc("_spawn_heart_clients", current_heart.position)
	
	print("Heart spawned at position: " + str(current_heart.position))

# ------------------------------------------------------------
# HELPER: Random heart spawn with edge padding
# ------------------------------------------------------------

func _get_random_heart_position() -> Vector2:
	# Ensure the heart doesn't spawn closer than 40 px to the window edges
	var padding := 40.0
	var x := randf_range(min_x + padding, max_x - padding)
	var y := randf_range(min_y + padding, max_y - padding)
	return Vector2(x, y)

# ------------------------------------------------------------
# CLIENT-SIDE HEART SPAWNING
# ------------------------------------------------------------

# Creates a heart on non-server peers so everyone can see it.
# We mark it call_local so that the function executes immediately
# on the receiving peer without a round-trip back to the server.
@rpc("authority", "call_local", "reliable")
func _spawn_heart_clients(position: Vector2):
	print("[Heart] _spawn_heart_clients called with position: " + str(position))
	
	# Avoid duplicating the heart on the server
	if multiplayer.is_server():
		print("[Heart] Client spawn ignored on server")
		return

	# Safety: ensure we don't already have a heart
	for child in get_tree().get_current_scene().get_node("Network/SpawnedNodes").get_children():
		if child is Heart:
			print("[Heart] Client already has a heart, skipping spawn")
			return

	print("[Heart] Client spawning heart at position: " + str(position))
	var heart = heart_scene.instantiate()
	heart.position = position
	get_tree().get_current_scene().get_node("Network/SpawnedNodes").add_child(heart)
	print("[Heart] Client heart spawned successfully")

# Send heart to a single newly-connected peer (called by NetworkManager)
@rpc("authority", "reliable")
func _spawn_heart_for_peer(position: Vector2, peer_id: int):
	# Only run this on the server; forward to target client
	if not multiplayer.is_server():
		return
	
	rpc_id(peer_id, "_spawn_heart_clients", position)

func _on_heart_collected():
	"""Called when a heart is collected by a player"""
	# Only process on server
	if not multiplayer.is_server():
		return
	
	# Clear the current heart reference
	current_heart = null
	
	# Start the timer to spawn a new heart in 30 seconds
	if hearts_enabled:
		heart_spawn_timer.start()
		print("Next heart will spawn in 30 seconds")

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

func drop_skull_on_death(player: Player):
	"""Drop skull when player dies if they're holding it"""
	if oddball_mode and skull_holder == player and current_skull:
		current_skull.drop_skull()

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
		for player in players_in_hill:
			if is_instance_valid(player):
				player.koth_score += 1
				
				# Sync score to all clients
				_sync_koth_score.rpc(player.player_id, player.koth_score)
				
				# Check for win condition
				if player.koth_score >= koth_win_score:
					_koth_win(player)
					return

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
