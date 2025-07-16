extends Area2D
class_name Heart

@onready var sprite = $Sprite2D
@onready var collection_sound = $CollectionSound

# Reference to game manager for respawning logic
var game_manager

func _ready():
	# Set up collision detection
	body_entered.connect(_on_body_entered)
	
	# Find the game manager
	game_manager = get_tree().get_current_scene().get_node("GameManager")
	
	# Set the heart sprite
	var heart_texture = load("res://Sprites/Tiles/heart.png")
	if sprite and heart_texture:
		sprite.texture = heart_texture
	
	# Add a subtle floating animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 10, 1.0)
	tween.tween_property(self, "position:y", position.y + 10, 1.0)
	
	# Add a gentle scale pulse
	var scale_tween = create_tween()
	scale_tween.set_loops()
	scale_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.8)
	scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.8)

func _on_body_entered(body):
	# Only process on server
	if not multiplayer.is_server():
		return
	
	# Check if it's a player
	if body is Player and body.is_alive:
		# Give the player an extra life
		body.lives_remaining += 1
		
		# Notify all clients about the collection
		_on_heart_collected.rpc(body.player_name, body.lives_remaining)
		
		# Tell the game manager a heart was collected
		if game_manager:
			game_manager._on_heart_collected()
		
		# Remove this heart
		queue_free()

@rpc("authority", "call_local", "reliable")
func _on_heart_collected(player_name: String, new_life_count: int):
	print(player_name + " collected a heart! (Lives: " + str(new_life_count) + ")")
	
	# Play collection sound on all clients
	if collection_sound:
		collection_sound.play()
	
	# Add visual feedback (particle effect or brief scale up)
	if sprite:
		var feedback_tween = create_tween()
		feedback_tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.2)
		feedback_tween.tween_property(sprite, "modulate:a", 0.0, 0.2) 