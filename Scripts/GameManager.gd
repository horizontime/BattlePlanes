extends Node

var players : Array[Player]
var local_player : Player

# Game configuration settings
var score_to_win : int = 3
var player_lives : int = 3
var max_players : int = 4
var speed_multiplier : float = 1.0
var damage_multiplier : float = 1.0
var has_time_limit : bool = false
var time_limit_minutes : int = 10

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

func apply_server_config(config: Dictionary):
	"""Apply server configuration settings to the game"""
	player_lives = config.get("player_lives", 3)
	max_players = config.get("max_players", 4)
	speed_multiplier = config.get("speed_multiplier", 1.0)
	damage_multiplier = config.get("damage_multiplier", 1.0)
	has_time_limit = config.get("has_time_limit", false)
	time_limit_minutes = config.get("time_limit_minutes", 10)
	
	# Start time limit if enabled
	if has_time_limit:
		time_limit_seconds = time_limit_minutes * 60.0
		game_timer.start()
		print("Game started with %d minute time limit" % time_limit_minutes)
	
	print("Server config applied: Lives=%d, MaxPlayers=%d, Speed=%.1fx, Damage=%.1fx" % [player_lives, max_players, speed_multiplier, damage_multiplier])

func _on_game_timer_timeout():
	"""Handle time limit countdown"""
	if has_time_limit and time_limit_seconds > 0:
		time_limit_seconds -= 1.0
		
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
	
	# Find player with highest score
	var highest_score = -1
	var winner: Player = null
	
	for player in players:
		if player.score > highest_score:
			highest_score = player.score
			winner = player
	
	if winner:
		end_game_clients.rpc(winner.player_name + " (Time Limit)")
	else:
		end_game_clients.rpc("Time Limit Reached")

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
	var x = randf_range(min_x, max_x)
	var y = randf_range(min_y, max_y)
	return Vector2(x, y)

# called when a player is killed (but still has lives)
func on_player_die (player_id : int, attacker_id : int):
	var player : Player = get_player(player_id)
	var attacker : Player = get_player(attacker_id)
	
	attacker.increase_score(1)
	
	if attacker.score >= score_to_win:
		end_game_clients.rpc(attacker.player_name)

# called when a player is eliminated (no lives remaining)
func on_player_eliminated (player_id : int, attacker_id : int):
	var player : Player = get_player(player_id)
	var attacker : Player = get_player(attacker_id)
	
	attacker.increase_score(1)
	
	print("Player %s eliminated! (%d lives remaining: %d)" % [player.player_name, player.player_name, player.lives_remaining])
	
	# Check if only one player remains alive
	var alive_players = []
	for p in players:
		if p.lives_remaining > 0:
			alive_players.append(p)
	
	if alive_players.size() <= 1 and alive_players.size() > 0:
		# Last player standing wins
		end_game_clients.rpc(alive_players[0].player_name + " (Last Standing)")
	elif attacker.score >= score_to_win:
		# Attacker reached score limit
		end_game_clients.rpc(attacker.player_name)

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
		# Reset lives to configured amount
		player.lives_remaining = player_lives
	
	# Reset time limit
	if has_time_limit:
		time_limit_seconds = time_limit_minutes * 60.0
		game_timer.start()
	
	reset_game_clients.rpc()

# called when the game resets on all CLIENTS
@rpc("authority", "call_local", "reliable")
func reset_game_clients ():
	end_screen.visible = false

# called when the game ends on all CLIENTS
@rpc("authority", "call_local", "reliable")
func end_game_clients (winner_name : String):
	end_screen.visible = true
	end_screen_winner_text.text = str(winner_name, " has won!")
	end_screen_button.visible = multiplayer.is_server()

func _on_play_again_button_pressed():
	reset_game()
