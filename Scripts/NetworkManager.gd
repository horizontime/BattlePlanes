extends Node

const MAX_CLIENTS : int = 4

@onready var network_ui = $NetworkUI
@onready var ip_input = $NetworkUI/VBoxContainer/IPInput
@onready var port_input = $NetworkUI/VBoxContainer/PortInput

# Server configuration
var server_config_scene = preload("res://Scenes/ServerConfig.tscn")
var server_config_ui = null
var current_server_config = {}

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
	
	# Check if port is in valid range (1024-65535 for user applications)
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

# show server configuration menu instead of immediately starting
func start_host ():
	# Validate port before proceeding
	if not _is_valid_port():
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
	_actually_start_server()

# called when user goes back from server config
func _on_server_config_back():
	server_config_ui.visible = false
	network_ui.visible = true
	
	# Hide game UI when returning to main menu
	var game_manager = get_tree().current_scene.get_node("GameManager")
	if game_manager:
		game_manager._hide_game_ui()

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

# join a multiplayer game
func start_client ():
	# Validate port before proceeding
	if not _is_valid_port():
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
	
	var player = player_scene.instantiate()
	player.name = str(id)
	player.player_id = id
	spawned_nodes.add_child(player, true)

	# If a heart currently exists, instruct server to send it to the new peer so they can see it
	if multiplayer.is_server():
		var game_manager = get_tree().current_scene.get_node("GameManager")
		if game_manager and game_manager.current_heart != null and is_instance_valid(game_manager.current_heart):
			game_manager._spawn_heart_for_peer(game_manager.current_heart.position, id)
		
		# Sync server configuration, cloud visibility and timer state to the new player
		if game_manager:
			game_manager._sync_config_to_peer(id)
			game_manager._sync_clouds_to_peer(id)
			game_manager._sync_timer_to_peer(id)

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
	
	# Show game UI when client connects to server
	var game_manager = get_tree().current_scene.get_node("GameManager")
	if game_manager:
		game_manager._show_game_ui()

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

func _on_username_input_text_changed(new_text):
	local_username = new_text

func get_server_config() -> Dictionary:
	return current_server_config
