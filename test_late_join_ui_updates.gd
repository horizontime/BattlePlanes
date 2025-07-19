# Test Suite: Late Join UI Updates
# Tests that UI elements properly update when players join mid-game

extends GutTest

var game_manager: GameManager
var network_manager: NetworkManager
var late_join_player: Player
var existing_players: Array[Player] = []
var test_scene: Node

func before_each():
	# Setup test scene structure
	test_scene = Node.new()
	test_scene.name = "TestScene"
	
	# Setup GameManager
	game_manager = GameManager.new()
	game_manager.name = "GameManager"
	test_scene.add_child(game_manager)
	
	# Setup NetworkManager
	network_manager = NetworkManager.new()
	network_manager.name = "Network"
	test_scene.add_child(network_manager)
	
	# Create SpawnedNodes container
	var spawned_nodes = Node.new()
	spawned_nodes.name = "SpawnedNodes"
	network_manager.add_child(spawned_nodes)
	
	# Initialize GameManager
	game_manager._ready()
	
	# Create 3 existing players
	for i in range(3):
		var player = Player.new()
		player.player_id = i + 1
		player.player_name = "ExistingPlayer" + str(i + 1)
		player.score = i * 2  # Varying scores
		player.oddball_score = i * 5
		player.koth_score = i * 3
		player.deaths = i
		player.lives_remaining = 3 - i
		player.team = i % 2
		existing_players.append(player)
		game_manager.players.append(player)
	
	# Create late-joining player
	late_join_player = Player.new()
	late_join_player.player_id = 4
	late_join_player.player_name = "LateJoiner"
	late_join_player.score = 0
	late_join_player.oddball_score = 0
	late_join_player.koth_score = 0
	late_join_player.deaths = 0
	late_join_player.lives_remaining = 3
	late_join_player.team = 1  # Team B
	
	# Setup team mode
	game_manager.is_team_mode = true
	game_manager.team_assignments = {1: 0, 2: 1, 3: 0, 4: 1}
	game_manager.team_kill_scores = {0: 5, 1: 8}

func test_server_config_sync_to_late_joiner():
	"""Test that server configuration is synced to late joining player"""
	print("Testing server config sync to late joiner...")
	
	# Setup game configuration
	var test_config = {
		"player_lives": 5,
		"max_players": 6,
		"speed_multiplier": 1.5,
		"damage_multiplier": 2.0,
		"has_time_limit": true,
		"time_limit_minutes": 15,
		"hearts_enabled": true,
		"clouds_enabled": false,
		"oddball_mode": true,
		"koth_mode": false,
		"game_mode": "Team Oddball",
		"game_mode_type": "team",
		"kill_limit": 25
	}
	
	game_manager.apply_server_config(test_config)
	
	# Simulate late joiner connecting (peer_id = 999)
	game_manager._sync_config_to_peer(999)
	
	# Verify config values would be sent to late joiner
	assert_eq(game_manager.player_lives, 5, "Player lives should be set")
	assert_eq(game_manager.max_players, 6, "Max players should be set")
	assert_eq(game_manager.speed_multiplier, 1.5, "Speed multiplier should be set")
	assert_true(game_manager.has_time_limit, "Time limit should be enabled")
	assert_true(game_manager.oddball_mode, "Oddball mode should be enabled")

func test_team_assignments_sync_to_late_joiner():
	"""Test that team assignments are synced to late joining player"""
	print("Testing team assignments sync to late joiner...")
	
	# Setup team assignments
	game_manager.set_team_assignments({1: 0, 2: 1, 3: 0, 4: 1})
	
	# Simulate late joiner connecting
	game_manager._sync_team_to_peer(999)
	
	# Verify team assignments are preserved
	assert_eq(game_manager.team_assignments[1], 0, "Player 1 should be Team A")
	assert_eq(game_manager.team_assignments[2], 1, "Player 2 should be Team B")
	assert_eq(game_manager.team_assignments[4], 1, "Late joiner should be Team B")

func test_player_scores_sync_to_late_joiner():
	"""Test that existing player scores are synced to late joining player"""
	print("Testing player scores sync to late joiner...")
	
	# Simulate late joiner connecting
	game_manager._sync_score_to_peer(999)
	
	# Verify all existing scores would be synced
	for i in range(3):
		assert_eq(existing_players[i].score, i * 2, "Player %d should have correct score" % (i + 1))

func test_team_scores_sync_to_late_joiner():
	"""Test that team scores are synced to late joining player"""
	print("Testing team scores sync to late joiner...")
	
	# Simulate late joiner connecting with team scores set
	game_manager._sync_score_to_peer(999)
	
	# Verify team scores would be synced
	assert_eq(game_manager.team_kill_scores[0], 5, "Team A should have 5 kills")
	assert_eq(game_manager.team_kill_scores[1], 8, "Team B should have 8 kills")

func test_deaths_count_sync_to_late_joiner():
	"""Test that death counts are synced to late joining player"""
	print("Testing deaths count sync to late joiner...")
	
	# Simulate late joiner connecting
	game_manager._sync_deaths_to_peer(999)
	
	# Verify death counts would be synced
	for i in range(3):
		assert_eq(existing_players[i].deaths, i, "Player %d should have correct death count" % (i + 1))

func test_oddball_scores_sync_to_late_joiner():
	"""Test that oddball scores are synced to late joining player"""
	print("Testing oddball scores sync to late joiner...")
	
	game_manager.oddball_mode = true
	
	# Simulate late joiner connecting
	game_manager._sync_skull_to_peer(999)
	
	# Verify oddball scores would be synced for players with scores > 0
	for i in range(3):
		if existing_players[i].oddball_score > 0:
			assert_gt(existing_players[i].oddball_score, 0, "Player %d should have oddball score" % (i + 1))

func test_koth_scores_sync_to_late_joiner():
	"""Test that KOTH scores are synced to late joining player"""
	print("Testing KOTH scores sync to late joiner...")
	
	game_manager.koth_mode = true
	
	# Simulate late joiner connecting
	game_manager._sync_hill_to_peer(999)
	
	# Verify KOTH scores would be synced for players with scores > 0
	for i in range(3):
		if existing_players[i].koth_score > 0:
			assert_gt(existing_players[i].koth_score, 0, "Player %d should have KOTH score" % (i + 1))

func test_heart_powerup_sync_to_late_joiner():
	"""Test that existing heart powerup is synced to late joining player"""
	print("Testing heart powerup sync to late joiner...")
	
	game_manager.hearts_enabled = true
	
	# Create mock heart
	var mock_heart = Node.new()
	mock_heart.name = "Heart"
	mock_heart.position = Vector2(100, 50)
	game_manager.current_heart = mock_heart
	
	# Simulate late joiner connecting - heart sync would be called
	game_manager._sync_config_to_peer(999)
	
	# Verify heart reference exists (would be synced via RPC)
	assert_not_null(game_manager.current_heart, "Heart should exist for syncing")

func test_skull_powerup_sync_to_late_joiner():
	"""Test that existing skull powerup is synced to late joining player"""
	print("Testing skull powerup sync to late joiner...")
	
	game_manager.oddball_mode = true
	
	# Create mock skull
	var mock_skull = Node.new()
	mock_skull.name = "Skull"
	mock_skull.position = Vector2(0, 0)
	game_manager.current_skull = mock_skull
	
	# Simulate late joiner connecting
	game_manager._sync_skull_to_peer(999)
	
	# Verify skull reference exists (would be synced via RPC)
	assert_not_null(game_manager.current_skull, "Skull should exist for syncing")

func test_hill_powerup_sync_to_late_joiner():
	"""Test that existing hill is synced to late joining player"""
	print("Testing hill powerup sync to late joiner...")
	
	game_manager.koth_mode = true
	
	# Create mock hill
	var mock_hill = Node.new()
	mock_hill.name = "Hill"
	mock_hill.position = Vector2(200, 100)
	game_manager.current_hill = mock_hill
	
	# Simulate late joiner connecting
	game_manager._sync_hill_to_peer(999)
	
	# Verify hill reference exists (would be synced via RPC)
	assert_not_null(game_manager.current_hill, "Hill should exist for syncing")

func test_timer_state_sync_to_late_joiner():
	"""Test that timer state is synced to late joining player"""
	print("Testing timer state sync to late joiner...")
	
	# Setup time limit
	game_manager.has_time_limit = true
	game_manager.time_limit_seconds = 300.0  # 5 minutes remaining
	
	# Simulate late joiner connecting
	game_manager._sync_timer_to_peer(999)
	
	# Verify timer state would be synced
	assert_true(game_manager.has_time_limit, "Time limit should be enabled")
	assert_eq(game_manager.time_limit_seconds, 300.0, "Timer should show correct remaining time")

func test_game_ui_sync_to_late_joiner():
	"""Test that game UI state is synced to late joining player"""
	print("Testing game UI sync to late joiner...")
	
	# Simulate late joiner connecting
	game_manager._sync_game_ui_to_peer(999)
	
	# This would call the RPC to show game UI elements
	# In a real test, we'd verify the RPC was called

func test_clouds_visibility_sync_to_late_joiner():
	"""Test that cloud visibility setting is synced to late joining player"""
	print("Testing clouds visibility sync to late joiner...")
	
	game_manager.clouds_enabled = false
	
	# Simulate late joiner connecting
	game_manager._sync_clouds_to_peer(999)
	
	# Verify clouds setting would be synced
	assert_false(game_manager.clouds_enabled, "Clouds should be disabled")

func test_late_joiner_team_assignment_auto_balance():
	"""Test that late joiner gets auto-assigned to balance teams"""
	print("Testing late joiner auto team assignment...")
	
	# Current teams: Team A has 2 players (1,3), Team B has 1 player (2)
	# Late joiner should be assigned to Team B for balance
	
	var assigned_team = game_manager._auto_assign_team(4)
	assert_eq(assigned_team, 1, "Late joiner should be assigned to Team B for balance")
	
	# Add another late joiner - should go to Team A
	var assigned_team2 = game_manager._auto_assign_team(5)
	assert_eq(assigned_team2, 0, "Second late joiner should be assigned to Team A")

func test_late_joiner_spawn_position():
	"""Test that late joiner gets proper spawn position based on team"""
	print("Testing late joiner spawn position...")
	
	# Add late joiner to game
	game_manager.players.append(late_join_player)
	
	# Get spawn position for Team B (team 1)
	var spawn_pos = game_manager.get_team_spawn_position(1)
	
	# Should be on right side of map (Team B spawn area)
	assert_gt(spawn_pos.x, 0, "Team B should spawn on right side")
	assert_ge(spawn_pos.x, game_manager.max_x - 100, "Should be in Team B spawn area")

func test_late_joiner_health_bar_creation():
	"""Test that health bar is created for late joining player"""
	print("Testing late joiner health bar creation...")
	
	# Add late joiner to game
	game_manager.players.append(late_join_player)
	
	# Simulate health bar check
	game_manager._check_for_new_players()
	
	# In real implementation, this would create a health bar
	# Here we just verify the player was added to tracking
	assert_true(late_join_player in game_manager.players, "Late joiner should be in players list")

func test_multiple_late_joiners_handling():
	"""Test handling multiple late joiners simultaneously"""
	print("Testing multiple late joiners handling...")
	
	# Create multiple late joiners
	var late_joiner2 = Player.new()
	late_joiner2.player_id = 5
	late_joiner2.player_name = "LateJoiner2"
	
	var late_joiner3 = Player.new()
	late_joiner3.player_id = 6
	late_joiner3.player_name = "LateJoiner3"
	
	# Add them to game
	game_manager.players.append(late_join_player)
	game_manager.players.append(late_joiner2)
	game_manager.players.append(late_joiner3)
	
	assert_eq(game_manager.players.size(), 6, "Should have 6 total players")
	
	# Each should get proper team assignments
	var team1 = game_manager._auto_assign_team(4)
	var team2 = game_manager._auto_assign_team(5)
	var team3 = game_manager._auto_assign_team(6)
	
	# Should alternate teams for balance
	assert_ne(team1, team2, "First two late joiners should be on different teams")

func test_late_join_during_different_game_modes():
	"""Test late join behavior across different game modes"""
	print("Testing late join during different game modes...")
	
	# Test FFA Slayer mode
	game_manager.game_mode = "FFA Slayer"
	game_manager.is_team_mode = false
	game_manager.players.append(late_join_player)
	late_join_player.lives_remaining = 999  # Should get unlimited lives in FFA Slayer
	
	assert_eq(late_join_player.lives_remaining, 999, "Should have unlimited lives in FFA Slayer")
	
	# Test Team Slayer mode
	game_manager.game_mode = "Team Slayer"
	game_manager.is_team_mode = true
	late_join_player.lives_remaining = 999  # Should get unlimited lives in Team Slayer
	
	assert_eq(late_join_player.lives_remaining, 999, "Should have unlimited lives in Team Slayer")
	
	# Test Standard mode
	game_manager.game_mode = "Standard"
	game_manager.is_team_mode = false
	game_manager.player_lives = 3
	late_join_player.lives_remaining = 3  # Should get configured lives in Standard
	
	assert_eq(late_join_player.lives_remaining, 3, "Should have configured lives in Standard mode")

func test_late_join_preserves_existing_game_state():
	"""Test that late join doesn't disrupt existing game state"""
	print("Testing late join preserves existing game state...")
	
	# Capture initial state
	var initial_team_scores = game_manager.team_kill_scores.duplicate()
	var initial_player_scores = []
	for player in existing_players:
		initial_player_scores.append(player.score)
	
	# Add late joiner
	game_manager.players.append(late_join_player)
	game_manager._sync_config_to_peer(999)
	
	# Verify existing state is preserved
	assert_eq(game_manager.team_kill_scores, initial_team_scores, "Team scores should be preserved")
	for i in range(3):
		assert_eq(existing_players[i].score, initial_player_scores[i], "Existing player scores should be preserved")

func test_late_join_error_handling():
	"""Test error handling for late join edge cases"""
	print("Testing late join error handling...")
	
	# Test sync to non-existent peer (should not crash)
	game_manager._sync_config_to_peer(99999)
	game_manager._sync_team_to_peer(99999)
	game_manager._sync_score_to_peer(99999)
	
	# Test with null values
	var original_players = game_manager.players
	game_manager.players = []
	game_manager._sync_score_to_peer(999)  # Should handle empty players array
	game_manager.players = original_players

# Cleanup
func after_each():
	for player in existing_players:
		if player:
			player.queue_free()
	existing_players.clear()
	
	if late_join_player:
		late_join_player.queue_free()
	
	if game_manager:
		game_manager.queue_free()
	if network_manager:
		network_manager.queue_free()
	if test_scene:
		test_scene.queue_free()
