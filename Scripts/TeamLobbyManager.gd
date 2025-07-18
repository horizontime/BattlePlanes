extends LobbyManager
class_name TeamLobbyManager

@onready var team_a_players = $VBoxContainer/TeamsContainer/TeamA/VBoxContainer/TeamAPlayers
@onready var team_b_players = $VBoxContainer/TeamsContainer/TeamB/VBoxContainer/TeamBPlayers

func _ready():
	super._ready()
	lobby_type = "team"

func _create_player_entry(player_id: int) -> Control:
	var container = HBoxContainer.new()
	
	# Player name
	var name_label = Label.new()
	var display_name = player_names.get(player_id, "Player " + str(player_id))
	name_label.text = display_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 14)
	
	# Host indicator
	if player_id == 1:  # Host is always ID 1
		var host_label = Label.new()
		host_label.text = "(Host)"
		host_label.add_theme_color_override("font_color", Color.YELLOW)
		host_label.add_theme_font_size_override("font_size", 12)
		container.add_child(host_label)
	
	container.add_child(name_label)
	
	return container

func _update_player_list():
	# Clear existing team entries
	for child in team_a_players.get_children():
		child.queue_free()
	for child in team_b_players.get_children():
		child.queue_free()
	
	# Add current players to teams
	var all_players = multiplayer.get_peers()
	all_players.append(multiplayer.get_unique_id())
	
	for player_id in all_players:
		var player_entry = _create_player_entry(player_id)
		
		# Simple team assignment: odd IDs = Team A, even IDs = Team B
		if player_id % 2 == 1:
			team_a_players.add_child(player_entry)
		else:
			team_b_players.add_child(player_entry)
