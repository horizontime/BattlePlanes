extends Panel

var game_manager
@onready var header_name = $VBoxContainer/Header/NameHeader
@onready var header_lives = $VBoxContainer/Header/LivesHeader
@onready var header_kills = $VBoxContainer/Header/KillsHeader
@onready var header_score = $VBoxContainer/Header/ScoreHeader
@onready var player_list = $VBoxContainer/PlayerList

var last_oddball_mode = false  # Track mode changes
var last_koth_mode = false  # Track KOTH mode changes

func _ready():
	game_manager = get_tree().get_current_scene().get_node("GameManager")
	
	# Set up table headers (will be updated dynamically in _process)
	header_name.text = "Name"

func _process(delta):
	# Update headers only when game mode changes
	if game_manager.oddball_mode != last_oddball_mode or game_manager.koth_mode != last_koth_mode:
		last_oddball_mode = game_manager.oddball_mode
		last_koth_mode = game_manager.koth_mode
		
		if game_manager.koth_mode:
			header_lives.text = "Score"  # Reuse lives header for KOTH score
			header_kills.text = "Kills"
			header_score.visible = false  # Don't need separate score column
		elif game_manager.oddball_mode:
			header_lives.text = "Score"  # Reuse lives header for score in oddball
			header_kills.text = "Kills"
			header_score.visible = false  # Don't need separate score column
		else:
			header_lives.text = "Lives"
			header_kills.text = "Kills"
			header_score.visible = false
	
	# Clear existing player entries
	for child in player_list.get_children():
		child.queue_free()
	
	# Create table rows for each player
	for player in game_manager.players:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		
		# Left spacer
		var left_spacer = Control.new()
		left_spacer.custom_minimum_size = Vector2(15, 0)
		
		# Name column
		var name_label = Label.new()
		name_label.text = player.player_name if player.player_name != "" else "Player " + str(player.player_id)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.custom_minimum_size.x = 50
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		
		# Lives/Score column (context dependent)
		var lives_label = Label.new()
		if game_manager.koth_mode:
			lives_label.text = str(player.koth_score)  # Show KOTH score
		elif game_manager.oddball_mode:
			lives_label.text = str(player.oddball_score)  # Show oddball score
		else:
			lives_label.text = str(player.lives_remaining)  # Show lives
		lives_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lives_label.custom_minimum_size.x = 40
		lives_label.add_theme_font_size_override("font_size", 11)
		lives_label.add_theme_color_override("font_color", Color.WHITE)
		
		# Kills column  
		var kills_label = Label.new()
		kills_label.text = str(player.score)
		kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kills_label.custom_minimum_size.x = 40
		kills_label.add_theme_font_size_override("font_size", 11)
		kills_label.add_theme_color_override("font_color", Color.WHITE)
		
		# Right spacer
		var right_spacer = Control.new()
		right_spacer.custom_minimum_size = Vector2(15, 0)
		
		# Add elements to row
		row.add_child(left_spacer)
		row.add_child(name_label)
		row.add_child(lives_label)
		row.add_child(kills_label)
		row.add_child(right_spacer)
		
		# Add row to player list
		player_list.add_child(row)
