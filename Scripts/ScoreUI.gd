extends Panel

var game_manager
@onready var header_name = $VBoxContainer/Header/NameHeader
@onready var header_lives = $VBoxContainer/Header/LivesHeader
@onready var header_kills = $VBoxContainer/Header/KillsHeader
@onready var header_score = $VBoxContainer/Header/ScoreHeader
@onready var player_list = $VBoxContainer/PlayerList

# Team score display elements (will be created dynamically)
var team_score_container = null
# Team Oddball skull status display
var skull_status_container = null

var last_oddball_mode = false  # Track mode changes
var last_koth_mode = false  # Track KOTH mode changes
var last_game_mode = ""  # Track game mode changes

func _ready():
	game_manager = get_tree().get_current_scene().get_node("GameManager")
	
	# Set up table headers (will be updated dynamically in _process)
	header_name.text = "Name"
	
	# Note: ScoreUI automatically listens to Team Oddball time updates via GameManager.team_skull_time
	# The GameManager receives update_team_oddball_time RPC calls and updates team_skull_time dictionary
	# which ScoreUI reads in _process() and _update_skull_status() for real-time UI refresh

func _process(delta):
	# Update headers only when game mode changes
	if game_manager.oddball_mode != last_oddball_mode or game_manager.koth_mode != last_koth_mode or game_manager.game_mode != last_game_mode:
		last_oddball_mode = game_manager.oddball_mode
		last_koth_mode = game_manager.koth_mode
		last_game_mode = game_manager.game_mode
		
		if game_manager.koth_mode:
			header_lives.text = "Score"  # Reuse lives header for KOTH score
			header_kills.text = "Kills"
			header_score.visible = false  # Don't need separate score column
		elif game_manager.game_mode == "Team Oddball":
			header_lives.text = "Skull Time"  # Replace "Score" with "Skull Time"
			header_kills.text = "Kills"
			header_score.visible = false  # Don't need separate score column
		elif game_manager.oddball_mode:
			header_lives.text = "Score"  # Reuse lives header for score in oddball
			header_kills.text = "Kills"
			header_score.visible = false  # Don't need separate score column
		elif game_manager.game_mode == "FFA Slayer":
			header_lives.text = "Deaths"  # Show deaths for FFA Slayer mode
			header_kills.text = "Kills"
			header_score.visible = false
		elif game_manager.game_mode == "Team Slayer":
			header_lives.text = "Team Kills"  # Repurpose lives header for Team Slayer
			header_kills.text = "Kills"
			header_score.visible = false
		else:
			header_lives.text = "Lives"
			header_kills.text = "Kills"
			header_score.visible = false
		
		# Update team score display visibility
		_update_team_score_display()
	
	# Update team scores in real-time if in Team Slayer mode
	if game_manager.game_mode == "Team Slayer" and team_score_container:
		_update_team_scores()
	 
	# Update Team Oddball skull status in real-time
	if game_manager.game_mode == "Team Oddball" and skull_status_container:
		_update_skull_status()
	
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
		elif game_manager.game_mode == "Team Oddball":
			# Show team skull time for this player's team
			if player.team == 0:
				lives_label.text = str(int(game_manager.team_skull_time[0])) + "s"
			else:
				lives_label.text = str(int(game_manager.team_skull_time[1])) + "s"
		elif game_manager.oddball_mode:
			lives_label.text = str(player.oddball_score)  # Show oddball score
		elif game_manager.game_mode == "FFA Slayer":
			lives_label.text = str(player.deaths)  # Show deaths for FFA Slayer mode
		elif game_manager.game_mode == "Team Slayer":
			# Show team score for this player's team
			if player.team == 0:
				lives_label.text = str(game_manager.team_kill_scores[0])
			else:
				lives_label.text = str(game_manager.team_kill_scores[1])
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
		
		# Color-code rows by team for clarity in Team Oddball mode
		if game_manager.game_mode == "Team Oddball":
			if player.team == 0:  # Team A
				name_label.add_theme_color_override("font_color", Color.CYAN)
				lives_label.add_theme_color_override("font_color", Color.CYAN)
				kills_label.add_theme_color_override("font_color", Color.CYAN)
			else:  # Team B
				name_label.add_theme_color_override("font_color", Color.YELLOW)
				lives_label.add_theme_color_override("font_color", Color.YELLOW)
				kills_label.add_theme_color_override("font_color", Color.YELLOW)
		
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

func _update_team_score_display():
	"""Create or hide team score display based on game mode"""
	if game_manager.game_mode == "Team Slayer":
		# Create team score display if it doesn't exist
		if team_score_container == null:
			team_score_container = VBoxContainer.new()
			team_score_container.name = "TeamScoreContainer"
			
			# Add team score container at the top
			$VBoxContainer.add_child(team_score_container)
			$VBoxContainer.move_child(team_score_container, 0)  # Move to top
			
			# Create team score labels
			var team_a_label = Label.new()
			team_a_label.name = "TeamALabel"
			team_a_label.text = "Team A: 0"
			team_a_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			team_a_label.add_theme_font_size_override("font_size", 12)
			team_a_label.add_theme_color_override("font_color", Color.CYAN)
			
			var team_b_label = Label.new()
			team_b_label.name = "TeamBLabel"
			team_b_label.text = "Team B: 0"
			team_b_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			team_b_label.add_theme_font_size_override("font_size", 12)
			team_b_label.add_theme_color_override("font_color", Color.YELLOW)
			
			# Add separator
			var separator = HSeparator.new()
			separator.add_theme_constant_override("separation", 5)
			
			team_score_container.add_child(team_a_label)
			team_score_container.add_child(team_b_label)
			team_score_container.add_child(separator)
	elif game_manager.game_mode == "Team Oddball":
		# Create Team Oddball skull time display if it doesn't exist
		if skull_status_container == null:
			skull_status_container = VBoxContainer.new()
			skull_status_container.name = "SkullStatusContainer"
			
			# Add skull status container at the top
			$VBoxContainer.add_child(skull_status_container)
			$VBoxContainer.move_child(skull_status_container, 0)  # Move to top
			
			# Create team skull time labels
			var team_a_time_label = Label.new()
			team_a_time_label.name = "TeamATimeLabel"
			team_a_time_label.text = "Team A: 0s"
			team_a_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			team_a_time_label.add_theme_font_size_override("font_size", 12)
			team_a_time_label.add_theme_color_override("font_color", Color.CYAN)
			
			var team_b_time_label = Label.new()
			team_b_time_label.name = "TeamBTimeLabel"
			team_b_time_label.text = "Team B: 0s"
			team_b_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			team_b_time_label.add_theme_font_size_override("font_size", 12)
			team_b_time_label.add_theme_color_override("font_color", Color.YELLOW)
			
			# Add separator
			var separator = HSeparator.new()
			separator.add_theme_constant_override("separation", 5)
			
			skull_status_container.add_child(team_a_time_label)
			skull_status_container.add_child(team_b_time_label)
			skull_status_container.add_child(separator)
	else:
			# Hide or remove containers for other modes
			if team_score_container:
				team_score_container.queue_free()
				team_score_container = null
			if skull_status_container:
				skull_status_container.queue_free()
				skull_status_container = null

func _update_team_scores():
	"""Update team score labels with current scores"""
	if team_score_container:
		var team_a_label = team_score_container.get_node("TeamALabel")
		var team_b_label = team_score_container.get_node("TeamBLabel")
		
		if team_a_label and team_b_label:
			team_a_label.text = "Team A: %d" % game_manager.team_kill_scores[0]
			team_b_label.text = "Team B: %d" % game_manager.team_kill_scores[1]

func _update_skull_status():
	"""Update team skull time labels with current times"""
	if skull_status_container:
		var team_a_time_label = skull_status_container.get_node("TeamATimeLabel")
		var team_b_time_label = skull_status_container.get_node("TeamBTimeLabel")
		
		if team_a_time_label and team_b_time_label:
			team_a_time_label.text = "Team A: %ds" % int(game_manager.team_skull_time[0])
			team_b_time_label.text = "Team B: %ds" % int(game_manager.team_skull_time[1])
