extends Node

var players : Array[Player]
var local_player : Player

var score_to_win : int = 3

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

# called when a player is killed
func on_player_die (player_id : int, attacker_id : int):
	var player : Player = get_player(player_id)
	var attacker : Player = get_player(attacker_id)
	
	attacker.increase_score(1)
	
	if attacker.score >= score_to_win:
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
