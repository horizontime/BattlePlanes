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
var player_names: Dictionary = {}  # Store player names by ID
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
	
	# Update initial player list and request local player name
	_request_local_player_name()
	_update_player_list()

func initialize_lobby(config: Dictionary, type: String):
	print("Initializing lobby with config: ", config)
	server_config = config
	lobby_type = type
	
	# Set mode display
	var mode_name = config.get("game_mode", "Custom")
	if mode_name.is_empty():
		mode_name = "Custom"
	if mode_label:
		mode_label.text = "Mode: " + mode_name
	
	# Update player count
	_update_player_count()

func _on_player_joined(id: int):
	print("Player %d joined lobby" % id)
	
	# First, ask all existing players to send their names to ensure we have them
	if multiplayer.is_server():
		_refresh_all_player_names()
		# Wait a frame for name requests to be processed
		await get_tree().process_frame
	
	# Then sync lobby state to new player (which will include all names)
	_sync_lobby_state_to_peer(id)
	
	# Request player name from new player
	_request_player_name.rpc_id(id)
	_update_player_list()
	_update_player_count()

func _on_player_left(id: int):
	print("Player %d left lobby" % id)
	if connected_players.has(id):
		connected_players.erase(id)
	if player_names.has(id):
		player_names.erase(id)
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
	# Handle leaving the lobby - return to main menu via window refresh
	if is_host:
		# Host triggers all clients to return to main menu
		_return_all_to_main_menu.rpc()
	
	# Refresh window to return to main menu
	get_tree().reload_current_scene()

@rpc("call_local", "reliable")
func _return_all_to_main_menu():
	# Called on all clients when host wants everyone to return to main menu
	get_tree().reload_current_scene()

@rpc("call_local", "reliable")
func _start_game_for_all():
	print("Starting game from lobby")
	game_started.emit()

@rpc("reliable")
func _sync_lobby_state_to_peer(peer_id: int):
	if not is_host:
		return
	
	print("Syncing lobby state to peer %d with player names: %s" % [peer_id, player_names])
	
	# Send lobby configuration to new peer
	_receive_lobby_state.rpc_id(peer_id, server_config, lobby_type, connected_players.keys(), player_names)

@rpc("reliable")
func _receive_lobby_state(config: Dictionary, type: String, player_ids: Array, names: Dictionary = {}):
	server_config = config
	lobby_type = type
	
	# Update player list from server
	for pid in player_ids:
		connected_players[pid] = true
	
	# Update player names from server
	player_names = names
	print("Received player names: ", player_names)
	
	# Send our own name to the server
	_request_local_player_name()
	
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
	var display_name = player_names.get(player_id, "Player " + str(player_id))
	name_label.text = display_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 14)
	
	# Highlight own username in yellow
	if player_id == multiplayer.get_unique_id():
		name_label.add_theme_color_override("font_color", Color.YELLOW)
	
	# You indicator
	if player_id == multiplayer.get_unique_id():
		var you_label = Label.new()
		you_label.text = "(You) "
		you_label.add_theme_color_override("font_color", Color.YELLOW)
		you_label.add_theme_font_size_override("font_size", 12)
		container.add_child(you_label)
	
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

func _request_local_player_name():
	var network_manager = get_tree().current_scene.get_node("Network")
	if network_manager:
		var username = network_manager.local_username
		if username.is_empty():
			username = _generate_default_name()
		player_names[multiplayer.get_unique_id()] = username
		# Send to server if we're a client, or broadcast if we're the server
		if not multiplayer.is_server():
			_send_player_name.rpc_id(1, multiplayer.get_unique_id(), username)
		else:
			# Server broadcasts their own name to all clients
			_update_player_name.rpc(multiplayer.get_unique_id(), username)

@rpc("any_peer", "reliable")
func _request_player_name():
	# Called on clients to request their name
	var network_manager = get_tree().current_scene.get_node("Network")
	if network_manager:
		var username = network_manager.local_username
		if username.is_empty():
			username = _generate_default_name()
		_send_player_name.rpc_id(1, multiplayer.get_unique_id(), username)



@rpc("any_peer", "reliable")
func _send_player_name(player_id: int, name: String):
	# Called on server to receive a player's name
	if multiplayer.is_server():
		player_names[player_id] = name
		# Broadcast updated name to all clients
		_update_player_name.rpc(player_id, name)
		_update_player_list()

@rpc("reliable")
func _update_player_name(player_id: int, name: String):
	# Called on all clients to update a player's name
	player_names[player_id] = name
	_update_player_list()

func _refresh_all_player_names():
	# Called on server to ensure we have names for all current players
	if not multiplayer.is_server():
		return
		
	# Make sure we have the server's own name
	var network_manager = get_tree().current_scene.get_node("Network")
	if network_manager:
		var username = network_manager.local_username
		if username.is_empty():
			username = _generate_default_name()
		player_names[1] = username  # Server is always ID 1
	
	# Request names from all connected clients
	var all_players = multiplayer.get_peers()
	for player_id in all_players:
		if not player_names.has(player_id):
			# We don't have this player's name, request it
			_request_player_name.rpc_id(player_id)

func _generate_default_name() -> String:
	var adjectives = ["Swift", "Bold", "Sharp", "Quick", "Brave", "Wild", "Fast", "Cool", "Hot", "Mega"]
	var nouns = ["Pilot", "Ace", "Flyer", "Wing", "Bird", "Jet", "Sky", "Star", "Fox", "Hero"]
	var adj = adjectives[randi() % adjectives.size()]
	var noun = nouns[randi() % nouns.size()]
	var num = randi() % 100
	return (adj + noun + str(num)).substr(0, 10)
