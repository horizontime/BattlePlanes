extends Node

const MAX_CLIENTS : int = 4

@onready var network_ui = $NetworkUI
@onready var ip_input = $NetworkUI/VBoxContainer/IPInput
@onready var port_input = $NetworkUI/VBoxContainer/PortInput
@onready var username_input = $NetworkUI/VBoxContainer/UsernameInput

# Server configuration
var server_config_scene = preload("res://Scenes/ServerConfig.tscn")
var server_config_ui = null
var current_server_config = {}

# Lobby scenes
var ffa_lobby_scene = preload("res://Scenes/FFALobby.tscn")
var team_lobby_scene = preload("res://Scenes/TeamLobby.tscn")
var current_lobby = null

var player_scene = preload("res://Scenes/Player.tscn")
@onready var spawned_nodes = $SpawnedNodes

var local_username : String

var spawn_x_range : float = 350
var spawn_y_range : float = 200

func _ready():
	pass

# Validate if the port input is valid
func _is_valid_port() -> bool:
	var port_text = port_input.text.strip_edges()
	
	# Check if port input is empty
	if port_text.is_empty():
		_show_port_error("Port is required! Please enter a port number.")
		return false
	
	# Check if port is a valid number
	if not port_text.is_valid_int():
		_show_port_error("Invalid port! Please enter a valid number.")
		return false
	
	var port_number = port_text.to_int()
	
	# Check if port is in valid range (1024 - 65535 for user applications)
	if port_number < 1024 or port_number > 65535:
		_show_port_error("Port must be between 1024 and 65535!")
		return false
	
	return true

# Show port validation error message
func _show_port_error(message: String):
	print("Port Error: " + message)
	# Highlight the port input to draw attention
	port_input.modulate = Color.RED
	port_input.placeholder_text = message
	port_input.text = ""
	
	# Reset the highlight after 3 seconds
	await get_tree().create_timer(3.0).timeout
	port_input.modulate = Color.WHITE
	port_input.placeholder_text = "Port..."

# Validate if the username input is valid
func _is_valid_username() -> bool:
	var username_text = username_input.text.strip_edges()
	
	# Check if username is empty
	if username_text.is_empty():
		_show_username_error("Username is required! Please enter a username.")
		return false
	
	# Check if username is too short
	if username_text.length() < 1:
		_show_username_error("Username must be at least 1 characters!")
		return false
	
	return true

# Show username validation error message
func _show_username_error(message: String):
	print("Username Error: " + message)
	# Highlight the username input to draw attention
	username_input.modulate = Color.RED
	username_input.placeholder_text = message
	username_input.text = ""
	
	# Reset the highlight after 3 seconds
	await get_tree().create_timer(3.0).timeout
	username_input.modulate = Color.WHITE
	username_input.placeholder_text = "Type a username..."

# show server configuration menu instead of immediately starting
func start_host ():
	# Validate port and username before proceeding
	if not _is_valid_port():
		return
	
	if not _is_valid_username():
		return
	
	# Create and show server configuration UI
	if server_config_ui == null:
		server_config_ui = server_config_scene.instantiate()
		get_tree().current_scene.add_child(server_config_ui)
		
		# Connect signals
		server_config_ui.server_config_confirmed.connect(_on_server_config_confirmed)
		server_config_ui.back_to_main_menu.connect(_on_server_config_back)
	
	# Hide main network UI and show config
	network_ui.visible = false
	server_config_ui.visible = true

# called when server configuration is confirmed
func _on_server_config_confirmed(config: Dictionary):
	current_server_config = config
	server_config_ui.visible = false
	_create_lobby_instead_of_server()

# called when user goes back from server config
func _on_server_config_back():
	server_config_ui.visible = false
	network_ui.visible = true
	
	# Hide game UI when returning to main menu
	var game_manager = get_tree().current_scene.get_node("GameManager")
	if game_manager:
		game_manager._hide_game_ui()

# create and show lobby instead of directly starting server
func _create_lobby_instead_of_server():
	# Start the actual server
	var max_clients = current_server_config.get("max_players", MAX_CLIENTS)
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(int(port_input.text), max_clients)
	multiplayer.multiplayer_peer = peer
	
	# Don't connect player_connected yet - lobby will handle this
	
	# Show appropriate lobby based on game mode type
	var mode_type = current_server_config.get("game_mode_type", "ffa")
	print("Creating lobby for mode type: ", mode_type)
	var lobby_scene = ffa_lobby_scene if mode_type == "ffa" else team_lobby_scene
	
	current_lobby = lobby_scene.instantiate()
	current_lobby.z_index = 100  # Make sure lobby is above NetworkUI
	get_tree().current_scene.add_child(current_lobby)
	print("Lobby created and added to scene")
	
	# Hide network UI and show lobby
	network_ui.visible = false
	current_lobby.visible = true
	
	# Force position the lobby to center of screen
	current_lobby.position = Vector2.ZERO
	
	# Connect lobby signals
	current_lobby.lobby_closed.connect(_on_lobby_closed)
	current_lobby.game_started.connect(_on_game_started_from_lobby)
	
	# Initialize lobby
	current_lobby.initialize_lobby(current_server_config, mode_type)
	
	# Notify any clients that might join later
	multiplayer.peer_connected.connect(_on_player_connected_to_lobby)

# actually create the server with the configured settings
func _actually_start_server():
	var max_clients = current_server_config.get("max_players", MAX_CLIENTS)
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(int(port_input.text), max_clients)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	# Apply configuration to GameManager
	var game_manager = get_tree().current_scene.get_node("GameManager")
	if game_manager:
		game_manager.apply_server_config(current_server_config)
	
	_on_player_connected(multiplayer.get_unique_id())

# called when lobby is closed (back button or disconnect)
func _on_lobby_closed():
	print("Lobby closed")
	if current_lobby:
		current_lobby.queue_free()
		current_lobby = null
	
	# Return to main menu
	network_ui.visible = true
	
	# Close multiplayer connection
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

# called when host starts game from lobby
func _on_game_started_from_lobby():
	print("Game started from lobby")
	
	# Disconnect lobby connection handler
	if multiplayer.peer_connected.is_connected(_on_player_connected_to_lobby):
		multiplayer.peer_connected.disconnect(_on_player_connected_to_lobby)
	
	# Now connect the actual game server signals
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	# Tell all clients to transition to game
	_transition_to_game.rpc()
	
	# Spawn players that are already connected
	var all_players = multiplayer.get_peers()
	all_players.append(multiplayer.get_unique_id())
	
	for player_id in all_players:
		_on_player_connected(player_id)

# called when a player connects to the lobby (server only)
func _on_player_connected_to_lobby(id: int):
	print("Player %d connected to lobby" % id)
	
	# Send lobby state to the new player
	var mode_type = current_server_config.get("game_mode_type", "ffa")
	print("Sending lobby state to player %d, mode: %s" % [id, mode_type])
	_create_client_lobby.rpc_id(id, current_server_config, mode_type)

# join a multiplayer game
func start_client ():
	# Validate port and username before proceeding
	if not _is_valid_port():
		return
	
	if not _is_valid_username():
		return
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_input.text, int(port_input.text))
	multiplayer.multiplayer_peer = peer
	
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)

# called on SERVER when a new player joins
# spawn in their player scene and set them up
func _on_player_connected (id : int):
	print("Player %s joined the game." % id)
	
	# Check if player already exists
	if spawned_nodes.has_node(str(id)):
		print("Player %s already exists, skipping spawn" % id)
		return
	
	var player = player_scene.instantiate()
	player.name = str(id)
	player.player_id = id
	spawned_nodes.add_child(player, true)
	print("Player %s spawned successfully" % id)

	# If a heart currently exists, instruct server to send it to the new peer so they can see it
	if multiplayer.is_server():
		var game_manager = get_tree().current_scene.get_node("GameManager")
		if game_manager and game_manager.current_heart != null and is_instance_valid(game_manager.current_heart):
			game_manager._spawn_heart_for_peer(game_manager.current_heart.position, id)
		
		# If a skull currently exists, instruct server to send it to the new peer so they can see it
		if game_manager:
			game_manager._sync_skull_to_peer(id)
		
		# If a hill currently exists, instruct server to send it to the new peer so they can see it
		if game_manager:
			game_manager._sync_hill_to_peer(id)
		
		# Sync server configuration, cloud visibility and timer state to the new player
		if game_manager:
			game_manager._sync_config_to_peer(id)
			game_manager._sync_clouds_to_peer(id)
			game_manager._sync_timer_to_peer(id)
			game_manager._sync_deaths_to_peer(id)
			game_manager._sync_score_to_peer(id)
			game_manager._sync_team_to_peer(id)
			game_manager._sync_game_ui_to_peer(id)

# called on the SERVER when a player leaves
# destroy their plane object
func _on_player_disconnected (id : int):
	print("Player %s left the game." % id)
	
	if not spawned_nodes.has_node(str(id)):
		return
	
	spawned_nodes.get_node(str(id)).queue_free()

# called on the CLIENT when they join a server
func _connected_to_server ():
	print("Connected to server.")
	network_ui.visible = false
	
	# Client will receive lobby state from server - wait for it
	# The lobby will be created when we receive the lobby state

# called on the CLIENT when connection to a server has failed
func _connection_failed ():
	print("Connection failed!")
	
	# Hide game UI on connection failure
	var game_manager = get_tree().current_scene.get_node("GameManager")
	if game_manager:
		game_manager._hide_game_ui()

# called on the CLIENT when they have left the server
func _server_disconnected ():
	print("Server disconnected.")
	network_ui.visible = true
	
	# Hide game UI when disconnecting from server
	var game_manager = get_tree().current_scene.get_node("GameManager")
	if game_manager:
		game_manager._hide_game_ui()
	
	# Hide server config if it's visible
	if server_config_ui:
		server_config_ui.visible = false
	
	# Close lobby if it's open
	if current_lobby:
		current_lobby.queue_free()
		current_lobby = null

func _on_username_input_text_changed(new_text):
	if new_text.length() > 10:
		var username_input = $NetworkUI/VBoxContainer/UsernameInput
		var caret_pos = username_input.caret_column
		username_input.text = new_text.substr(0, 10)
		username_input.caret_column = min(caret_pos, 10)
		new_text = username_input.text
	local_username = new_text

func _on_port_input_text_changed(new_text):
	if new_text.length() > 5:
		var port_input = $NetworkUI/VBoxContainer/PortInput
		var caret_pos = port_input.caret_column
		port_input.text = new_text.substr(0, 5)
		port_input.caret_column = min(caret_pos, 5)

func get_server_config() -> Dictionary:
	return current_server_config

# RPC functions for lobby management
@rpc("reliable")
func _create_client_lobby(config: Dictionary, mode_type: String):
	print("Creating client lobby for mode: ", mode_type)
	current_server_config = config
	
	# Create appropriate lobby scene
	var lobby_scene = ffa_lobby_scene if mode_type == "ffa" else team_lobby_scene
	current_lobby = lobby_scene.instantiate()
	current_lobby.z_index = 100  # Make sure lobby is above NetworkUI
	get_tree().current_scene.add_child(current_lobby)
	print("Client lobby created and added to scene")
	
	# Make sure lobby is visible
	current_lobby.visible = true
	
	# Force position the lobby to center of screen
	current_lobby.position = Vector2.ZERO
	
	# Connect lobby signals
	current_lobby.lobby_closed.connect(_on_lobby_closed)
	current_lobby.game_started.connect(_on_game_started_from_lobby)
	
	# Initialize lobby
	current_lobby.initialize_lobby(config, mode_type)

@rpc("call_local", "reliable")
func _transition_to_game():
	print("Transitioning from lobby to game")
	if current_lobby:
		current_lobby.visible = false  # Hide immediately
		current_lobby.queue_free()
		current_lobby = null
	
	# Make sure NetworkUI is hidden
	network_ui.visible = false
	
	# Show game UI
	var game_manager = get_tree().current_scene.get_node("GameManager")
	if game_manager:
		game_manager._show_game_ui()
		if multiplayer.is_server():
			game_manager.apply_server_config(current_server_config)
			# Show timer UI if game has time limit
			if game_manager.has_time_limit:
				game_manager._show_timer_ui()
	
	print("Game transition completed")
