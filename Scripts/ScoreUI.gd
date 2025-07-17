extends Panel

var game_manager
@onready var header_name = $VBoxContainer/Header/NameHeader
@onready var header_lives = $VBoxContainer/Header/LivesHeader
@onready var header_kills = $VBoxContainer/Header/KillsHeader
@onready var player_list = $VBoxContainer/PlayerList

func _ready():
	game_manager = get_tree().get_current_scene().get_node("GameManager")
	
	# Set up table headers
	header_name.text = "Name"
	header_lives.text = "Lives"
	header_kills.text = "Kills"

func _process(delta):
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
		
		# Lives column
		var lives_label = Label.new()
		lives_label.text = str(player.lives_remaining)
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
