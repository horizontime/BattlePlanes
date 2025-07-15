extends Node

const MAX_CLIENTS : int = 4

@onready var network_ui = $NetworkUI
@onready var ip_input = $NetworkUI/VBoxContainer/IPInput
@onready var port_input = $NetworkUI/VBoxContainer/PortInput

var player_scene = preload("res://Scenes/Player.tscn")
@onready var spawned_nodes = $SpawnedNodes

var local_username : String

var spawn_x_range : float = 350
var spawn_y_range : float = 200

func _ready():
	pass

# create a multiplayer game
func start_host ():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(int(port_input.text), MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	_on_player_connected(multiplayer.get_unique_id())
	
	network_ui.visible = false

# join a multiplayer game
func start_client ():
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

# called on the CLIENT when connection to a server has failed
func _connection_failed ():
	print("Connection failed!")

# called on the CLIENT when they have left the server
func _server_disconnected ():
	print("Server disconnected.")
	network_ui.visible = true

func _on_username_input_text_changed(new_text):
	local_username = new_text
