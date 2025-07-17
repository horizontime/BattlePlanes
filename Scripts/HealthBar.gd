extends Control
class_name HealthBar

@onready var health_progress : ProgressBar = $HealthProgress
@onready var background : NinePatchRect = $Background
@onready var health_label : Label = $HealthLabel
@onready var name_label : Label = $NameLabel

var target_player : Player = null

func _ready():
	# Set high z-index to appear above game objects
	z_index = 100
	# Position the health bar above the player
	if target_player:
		update_health_display()

func _process(_delta):
	if target_player and target_player.is_alive:
		# Keep the health bar positioned above the player
		global_position = target_player.global_position + Vector2(-25, -45)
		update_health_display()
		visible = true
	else:
		# Hide health bar when player is dead
		visible = false

func set_target_player(player: Player):
	target_player = player
	if target_player:
		update_health_display()
		visible = true

func update_health_display():
	if not target_player:
		return
	
	var health_percentage = float(target_player.cur_hp) / float(target_player.max_hp) * 100.0
	health_progress.value = health_percentage
	
	# Show health and lives remaining
	health_label.text = "%d/%d ♥%d" % [target_player.cur_hp, target_player.max_hp, target_player.lives_remaining]
	
	# Update player name
	if name_label and target_player.player_name != "":
		name_label.text = target_player.player_name
	
	# Change color based on health level
	if health_percentage > 60:
		health_progress.modulate = Color.GREEN
	elif health_percentage > 30:
		health_progress.modulate = Color.YELLOW
	else:
		health_progress.modulate = Color.RED
	
	# Show/hide based on whether player is alive
	visible = target_player.is_alive 
