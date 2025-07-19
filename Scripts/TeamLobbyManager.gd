extends LobbyManager
class_name TeamLobbyManager

@onready var team_a_players = $VBoxContainer/TeamsContainer/TeamA/VBoxContainer/TeamAPlayers
@onready var team_b_players = $VBoxContainer/TeamsContainer/TeamB/VBoxContainer/TeamBPlayers
@onready var team_switch_button = $VBoxContainer/TeamsContainer/TeamSwitchContainer/TeamSwitchButton

# Team assignments: player_id -> team (0 = Team A, 1 = Team B)
var team_assignments: Dictionary = {}

func _ready():
	super._ready()
	lobby_type = "team"
	team_switch_button.pressed.connect(_on_team_switch_pressed)

func _create_player_entry(player_id: int) -> Control:
	var container = HBoxContainer.new()
	
	# Player name
	var name_label = Label.new()
	var display_name = player_names.get(player_id, "Player " + str(player_id))
	name_label.text = display_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 14)
	
	# Highlight own username in yellow
	if player_id == multiplayer.get_unique_id():
		name_label.add_theme_color_override("font_color", Color.YELLOW)
	
	# You indicator
	if player_id == multiplayer.get_unique_id():
		var you_label = Label.new()
		you_label.text = "(You) "
		you_label.add_theme_color_override("font_color", Color.YELLOW)
		you_label.add_theme_font_size_override("font_size", 12)
		container.add_child(you_label)
	
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
		# Auto-assign new players to the team with fewer members
		if not team_assignments.has(player_id):
			var team_a_count = _count_team_members(0)
			var team_b_count = _count_team_members(1)
			team_assignments[player_id] = 0 if team_a_count <= team_b_count else 1
		
		var player_entry = _create_player_entry(player_id)
		
		# Add player to their assigned team
		if team_assignments.get(player_id, 0) == 0:
			team_a_players.add_child(player_entry)
		else:
			team_b_players.add_child(player_entry)

func _count_team_members(team: int) -> int:
	"""Count how many players are on the specified team (0 = Team A, 1 = Team B)"""
	var count = 0
	for player_id in team_assignments:
		if team_assignments[player_id] == team:
			count += 1
	return count

func _on_team_switch_pressed():
	"""Handle team switch button press"""
	var local_player_id = multiplayer.get_unique_id()
	
	# Toggle team assignment for local player
	if team_assignments.has(local_player_id):
		team_assignments[local_player_id] = 1 - team_assignments[local_player_id]
	else:
		team_assignments[local_player_id] = 1  # Default to Team B if not assigned
	
	# Sync team assignment to server if we're not the server
	if not multiplayer.is_server():
		_sync_team_assignment.rpc_id(1, local_player_id, team_assignments[local_player_id])
	else:
		# Server broadcasts to all clients
		_sync_team_assignment.rpc(local_player_id, team_assignments[local_player_id])
	
	_update_player_list()

@rpc("any_peer", "reliable")
func _sync_team_assignment(player_id: int, team: int):
	"""Sync team assignment across all clients"""
	team_assignments[player_id] = team
	_update_player_list()

	# If we are the server and this change originated from a client (sender != 0),
	# relay the update to every peer so all lobbies stay consistent.
	if multiplayer.is_server():
		var sender_id := multiplayer.get_remote_sender_id()
		# Relay the update to every peer **except** the one who sent it (they already updated)
		for peer_id in multiplayer.get_peers():
			if peer_id != sender_id:
				_sync_team_assignment.rpc_id(peer_id, player_id, team)

func get_team_assignments() -> Dictionary:
	"""Get current team assignments for use by GameManager"""
	return team_assignments.duplicate()

@rpc("call_local", "reliable")
func _start_game_for_all():
	print("Starting team game from lobby")
	
	# Pass team assignments to GameManager before emitting game_started
	var game_manager = get_tree().get_current_scene().get_node_or_null("GameManager")
	if game_manager and game_manager.has_method("set_team_assignments"):
		game_manager.set_team_assignments(team_assignments)
	
	game_started.emit()
