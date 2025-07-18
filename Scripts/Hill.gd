extends Area2D
class_name Hill

signal player_entered_hill(player: Player)
signal player_exited_hill(player: Player)

var players_in_hill: Array[Player] = []
var hill_radius: float = 80.0

@onready var visual = $Visual
@onready var collision_shape = $CollisionShape2D

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set up collision shape
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = hill_radius
	collision_shape.shape = circle_shape
	
	# Set up visual with same radius
	visual.hill_radius = hill_radius

func _on_body_entered(body):
	if body is Player and body not in players_in_hill:
		players_in_hill.append(body)
		player_entered_hill.emit(body)
		print("Player " + body.player_name + " entered the hill")

func _on_body_exited(body):
	if body is Player and body in players_in_hill:
		players_in_hill.erase(body)
		player_exited_hill.emit(body)
		print("Player " + body.player_name + " exited the hill")

func get_players_in_hill() -> Array[Player]:
	return players_in_hill

func move_to_position(new_position: Vector2):
	"""Move hill to a new position with bounds checking"""
	# Get map boundaries from GameManager
	var game_manager = get_tree().get_current_scene().get_node("GameManager")
	if game_manager:
		var padding = hill_radius + 20  # Extra padding to ensure full circle is visible
		var min_x = game_manager.min_x + padding
		var max_x = game_manager.max_x - padding
		var min_y = game_manager.min_y + padding
		var max_y = game_manager.max_y - padding
		
		# Clamp position to keep hill fully visible
		new_position.x = clamp(new_position.x, min_x, max_x)
		new_position.y = clamp(new_position.y, min_y, max_y)
	
	position = new_position
	visual.queue_redraw()  # Redraw the visual at new position
