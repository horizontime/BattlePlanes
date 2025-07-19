extends Area2D
class_name Skull

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

var holder_player: Player = null
var holder_team_id: int = -1  # Store team ID of current holder (-1 = no team/FFA)
var is_held: bool = false
var follow_offset: Vector2 = Vector2(0, -30)  # Offset relative to player

signal skull_picked_up(player: Player)
signal skull_dropped()

func _ready():
	# Set up the skull sprite
	var skull_texture = load("res://Sprites/Tiles/Skull.png")
	sprite.texture = skull_texture
	
	# Create collision shape for pickup detection
	var shape = CircleShape2D.new()
	shape.radius = 20
	collision_shape.shape = shape
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	
	# Ensure this is only processed on the server
	set_process(multiplayer.is_server())

func _process(delta):
	# Only server processes following logic
	if multiplayer.is_server() and is_held and holder_player and is_instance_valid(holder_player):
		# Follow the holder player
		position = holder_player.position + follow_offset
		# Sync position to all clients
		_sync_position.rpc(position)

func _on_body_entered(body):
	# Only process on server
	if not multiplayer.is_server():
		return
		
	if body is Player and not is_held:
		# Prevent immediate pickup if player has just spawned
		if body.has_method("can_pickup_items") and not body.can_pickup_items():
			return
		pickup_skull(body)

func pickup_skull(player: Player):
	"""Server-side skull pickup logic"""
	if not multiplayer.is_server() or is_held:
		return
	
	holder_player = player
	holder_team_id = player.team  # Store the team ID of the holder
	is_held = true
	
	# Hide collision detection while held
	collision_shape.disabled = true
	
	# Notify clients about the pickup
	_pickup_skull_clients.rpc(player.player_id)
	
	# Emit signal for GameManager to handle scoring
	skull_picked_up.emit(player)
	
	print("Skull picked up by: " + player.player_name)

func drop_skull():
	"""Server-side skull drop logic"""
	if not multiplayer.is_server() or not is_held:
		return
	
	is_held = false
	holder_player = null
	holder_team_id = -1  # Reset team ID when dropped
	
	# Re-enable collision detection
	collision_shape.disabled = false
	
	# Notify clients about the drop
	_drop_skull_clients.rpc()
	
	# Emit signal for GameManager
	skull_dropped.emit()
	
	print("Skull dropped!")

func drop_skull_at_position(drop_position: Vector2):
	"""Server-side skull drop logic at a specific position (e.g., corpse location)"""
	if not multiplayer.is_server() or not is_held:
		return
	
	# Set the skull position to the drop location
	position = drop_position
	
	is_held = false
	holder_player = null
	holder_team_id = -1  # Reset team ID when dropped
	
	# Re-enable collision detection
	collision_shape.disabled = false
	
	# Notify clients about the drop with the new position
	_drop_skull_at_position_clients.rpc(drop_position)
	
	# Emit signal for GameManager
	skull_dropped.emit()
	
	print("Skull dropped at corpse position: " + str(drop_position))

@rpc("authority", "call_local", "reliable")
func _pickup_skull_clients(player_id: int):
	"""Client-side visual updates for skull pickup"""
	# Find the player
	var game_manager = get_tree().get_current_scene().get_node("GameManager")
	holder_player = game_manager.get_player(player_id)
	if holder_player:
		holder_team_id = holder_player.team  # Sync team ID on clients
	is_held = true
	collision_shape.disabled = true

@rpc("authority", "call_local", "reliable")
func _drop_skull_clients():
	"""Client-side visual updates for skull drop"""
	is_held = false
	holder_player = null
	holder_team_id = -1  # Reset team ID on clients
	collision_shape.disabled = false

@rpc("authority", "call_local", "reliable")
func _drop_skull_at_position_clients(drop_position: Vector2):
	"""Client-side visual updates for skull drop at specific position"""
	position = drop_position
	is_held = false
	holder_player = null
	holder_team_id = -1  # Reset team ID on clients
	collision_shape.disabled = false

@rpc("authority", "call_local", "reliable")
func _sync_position(new_position: Vector2):
	"""Sync skull position to all clients"""
	if not multiplayer.is_server():
		position = new_position
