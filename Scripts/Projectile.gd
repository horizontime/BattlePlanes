extends Area2D

@export var speed : float = 500.0
@export var base_damage : int = 10  # Base damage before multiplier
var owner_id : int

func _ready():
	if not multiplayer.is_server():
		set_physics_process(false)

func _physics_process(delta):
	position += -transform.y * speed * delta

func _on_body_entered(body):
	if not multiplayer.is_server():
		return
	
	if not body.is_in_group("Player"):
		return
	
	if body.player_id == owner_id:
		return
	
	# Apply damage multiplier from game configuration
	var damage = base_damage
	var game_manager = get_tree().current_scene.get_node("GameManager")
	if game_manager:
		damage = int(base_damage * game_manager.damage_multiplier)
	
	body.take_damage(damage, owner_id)
	queue_free()

func _on_timer_timeout():
	if multiplayer.is_server():
		queue_free()
