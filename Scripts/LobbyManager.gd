extends Control
class_name LobbyManager

signal lobby_closed
signal game_started

@onready var player_list = $VBoxContainer/PlayerListContainer/ScrollContainer/PlayerList
@onready var start_game_button = $VBoxContainer/ButtonContainer/StartGameButton
@onready var back_button = $VBoxContainer/ButtonContainer/BackButton
@onready var mode_label = $VBoxContainer/Header/ModeLabel
@onready var player_count_label = $VBoxContainer/Header/PlayerCountLabel

var server_config: Dictionary = {}
var connected_players: Dictionary = {}
var is_host: bool = false
var lobby_type: String = "ffa"  # "ffa" or "team"

func _ready():
	print("Lobby Manager _ready() called")
	print("Node references - player_list: ", player_list)
	print("Node references - start_game_button: ", start_game_button)
	print("Node references - back_button: ", back_button)
	print("Node references - mode_label: ", mode_label)
	print("Node references - player_count_label: ", player_count_label)
	
	# Connect buttons
	if start_game_button:
		start_game_button.pressed.connect(_on_start_game_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_player_joined)
	multiplayer.peer_disconnected.connect(_on_player_left)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Hide start button for non-hosts
	is_host = multiplayer.is_server()
	if start_game_button:
		start_game_button.visible = is_host
	
	# Update initial player list
	_update_player_list()

func initialize_lobby(config: Dictionary, type: String):
	print("Initializing lobby with config: ", config)
	server_config = config
	lobby_type = type
	
	# Set mode display
	var mode_name = config.get("mode_name", "Unknown")
	if mode_label:
		mode_label.text = "Mode: " + mode_name
	
	# Update player count
	_update_player_count()

func _on_player_joined(id: int):
	print("Player %d joined lobby" % id)
	_sync_lobby_state_to_peer(id)
	_update_player_list()
	_update_player_count()

func _on_player_left(id: int):
	print("Player %d left lobby" % id)
	if connected_players.has(id):
		connected_players.erase(id)
	_update_player_list()
	_update_player_count()

func _on_server_disconnected():
	print("Server disconnected from lobby")
	lobby_closed.emit()

func _on_start_game_pressed():
	if not is_host:
		return
	
	# Start the game for all players
	_start_game_for_all.rpc()

func _on_back_pressed():
	# Handle leaving the lobby
	if is_host:
		# Host closes the lobby
		multiplayer.multiplayer_peer.close()
	else:
		# Client leaves the lobby
		multiplayer.multiplayer_peer.close()
	
	lobby_closed.emit()

@rpc("call_local", "reliable")
func _start_game_for_all():
	print("Starting game from lobby")
	game_started.emit()

@rpc("reliable")
func _sync_lobby_state_to_peer(peer_id: int):
	if not is_host:
		return
	
	# Send lobby configuration to new peer
	_receive_lobby_state.rpc_id(peer_id, server_config, lobby_type, connected_players.keys())

@rpc("reliable")
func _receive_lobby_state(config: Dictionary, type: String, player_ids: Array):
	server_config = config
	lobby_type = type
	
	# Update player list from server
	for pid in player_ids:
		connected_players[pid] = true
	
	_update_player_list()
	_update_player_count()

func _update_player_list():
	if not player_list:
		print("Player list node not found!")
		return
		
	# Clear existing player entries
	for child in player_list.get_children():
		child.queue_free()
	
	# Add current players
	var all_players = multiplayer.get_peers()
	all_players.append(multiplayer.get_unique_id())
	
	for player_id in all_players:
		var player_entry = _create_player_entry(player_id)
		player_list.add_child(player_entry)

func _create_player_entry(player_id: int) -> Control:
	var container = HBoxContainer.new()
	
	# Player name
	var name_label = Label.new()
	name_label.text = "Player " + str(player_id)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 14)
	
	# Host indicator
	if player_id == 1:  # Host is always ID 1
		var host_label = Label.new()
		host_label.text = "(Host)"
		host_label.add_theme_color_override("font_color", Color.YELLOW)
		host_label.add_theme_font_size_override("font_size", 12)
		container.add_child(host_label)
	
	container.add_child(name_label)
	
	# Team assignment for team modes
	if lobby_type == "team":
		var team_label = Label.new()
		# Simple team assignment: odd IDs = Team A, even IDs = Team B
		var team = "Team A" if player_id % 2 == 1 else "Team B"
		team_label.text = team
		team_label.add_theme_color_override("font_color", Color.CYAN if team == "Team A" else Color.ORANGE)
		team_label.add_theme_font_size_override("font_size", 12)
		container.add_child(team_label)
	
	return container

func _update_player_count():
	var current_count = len(multiplayer.get_peers()) + 1  # +1 for self
	var max_count = server_config.get("max_players", 4)
	if player_count_label:
		player_count_label.text = "Players: %d/%d" % [current_count, max_count]
