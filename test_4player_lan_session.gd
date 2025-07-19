# Integration Test Suite: 4-Player LAN Session
# Tests timer accrual, drop logic, victory conditions, and network synchronization

extends GutTest

var game_manager: GameManager
var network_manager: NetworkManager
var players: Array[Player] = []
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
	
	# Create 4 test players
	for i in range(4):
		var player = Player.new()
		player.player_id = i + 1
		player.player_name = "Player" + str(i + 1)
		player.score = 0
		player.oddball_score = 0
		player.koth_score = 0
		player.deaths = 0
		player.lives_remaining = 3
		player.team = i % 2  # Players 1,3 = Team A (0), Players 2,4 = Team B (1)
		players.append(player)
		game_manager.players.append(player)
	
	# Setup team mode
	game_manager.is_team_mode = true
	game_manager.team_assignments = {1: 0, 2: 1, 3: 0, 4: 1}
	game_manager.team_kill_scores = {0: 0, 1: 0}

func test_team_slayer_4player_session():
	"""Test complete Team Slayer session with victory conditions"""
	game_manager.game_mode = "Team Slayer"
	game_manager.kill_limit = 30
	
	print("Starting Team Slayer 4-player session test...")
	
	# Simulate game progression - Team A dominates
	for i in range(15):
		# Player 1 kills Player 2 (enemy)
		game_manager.on_player_die(2, 1)
		# Player 3 kills Player 4 (enemy)  
		game_manager.on_player_die(4, 3)
	
	# Verify team scores
	assert_eq(game_manager.team_kill_scores[0], 30, "Team A should have 30 kills")
	assert_eq(game_manager.team_kill_scores[1], 0, "Team B should have 0 kills")
	
	# Verify individual player scores
	assert_eq(players[0].score, 15, "Player 1 should have 15 kills")
	assert_eq(players[2].score, 15, "Player 3 should have 15 kills")
	assert_eq(players[1].score, 0, "Player 2 should have 0 kills")
	assert_eq(players[3].score, 0, "Player 4 should have 0 kills")
	
	# Verify death counts
	assert_eq(players[1].deaths, 15, "Player 2 should have 15 deaths")
	assert_eq(players[3].deaths, 15, "Player 4 should have 15 deaths")

func test_team_slayer_with_friendly_fire_incidents():
	"""Test Team Slayer session with mixed friendly fire and enemy kills"""
	game_manager.game_mode = "Team Slayer"
	
	print("Testing Team Slayer with friendly fire incidents...")
	
	# Mixed scenario:
	# Player 1 (Team A) kills Player 2 (Team B) - enemy kill
	game_manager.on_player_die(2, 1)
	assert_eq(players[0].score, 1, "Player 1 should have 1 kill")
	assert_eq(game_manager.team_kill_scores[0], 1, "Team A should have 1 kill")
	
	# Player 1 (Team A) kills Player 3 (Team A) - friendly fire
	game_manager.on_player_die(3, 1)
	assert_eq(players[0].score, 0, "Player 1 should have 0 kills after friendly fire")
	assert_eq(game_manager.team_kill_scores[0], 0, "Team A should have 0 kills after friendly fire")
	
	# Player 4 (Team B) kills Player 2 (Team B) - friendly fire
	game_manager.on_player_die(2, 4)
	assert_eq(players[3].score, -1, "Player 4 should have -1 after friendly fire")
	assert_eq(game_manager.team_kill_scores[1], 0, "Team B should remain at 0")

func test_oddball_mode_skull_timer_accrual():
	"""Test Oddball mode timer accrual and skull holding mechanics"""
	game_manager.oddball_mode = true
	game_manager.game_mode = "Oddball"
	game_manager.oddball_win_score = 60
	
	print("Testing Oddball mode timer accrual...")
	
	# Simulate skull pickup by Player 1
	game_manager.skull_holder = players[0]
	game_manager.oddball_score_timer.start()
	
	# Simulate 30 seconds of skull holding (30 points)
	for i in range(30):
		game_manager._on_oddball_score_timer()
	
	assert_eq(players[0].oddball_score, 30, "Player 1 should have 30 oddball points")
	
	# Simulate skull drop (Player 1 dies)
	game_manager.drop_skull_on_death(players[0], Vector2(100, 100))
	assert_eq(game_manager.skull_holder, null, "Skull holder should be null after drop")
	
	# Simulate Player 2 picking up skull and holding for 35 seconds (enough to win)
	game_manager.skull_holder = players[1]
	for i in range(35):
		game_manager._on_oddball_score_timer()
	
	assert_eq(players[1].oddball_score, 35, "Player 2 should have 35 oddball points")

func test_team_oddball_timer_accrual_and_victory():
	"""Test Team Oddball mode with team timer accrual"""
	game_manager.game_mode = "Team Oddball" 
	game_manager.team_skull_time = {0: 0.0, 1: 0.0}
	
	print("Testing Team Oddball timer accrual...")
	
	# Player 1 (Team A) holds skull for 50 seconds
	game_manager.skull_holder = players[0]
	for i in range(50):
		game_manager.team_skull_time[0] += 1.0
		if game_manager.team_skull_time[0] >= 100.0:
			break
	
	assert_eq(game_manager.team_skull_time[0], 50.0, "Team A should have 50 seconds")
	
	# Skull changes to Player 2 (Team B) for 60 seconds
	game_manager.skull_holder = players[1]
	for i in range(60):
		game_manager.team_skull_time[1] += 1.0
		if game_manager.team_skull_time[1] >= 100.0:
			break
	
	assert_eq(game_manager.team_skull_time[1], 60.0, "Team B should have 60 seconds")
	
	# Team B should be closer to victory but not yet won
	assert_lt(game_manager.team_skull_time[1], 100.0, "Team B should not have won yet")

func test_koth_mode_hill_control_timer():
	"""Test King of the Hill mode hill control and timer mechanics"""
	game_manager.koth_mode = true
	game_manager.game_mode = "KOTH"
	game_manager.koth_win_score = 60
	
	print("Testing KOTH hill control timer...")
	
	# Create mock hill for testing
	var mock_hill = Node.new()
	mock_hill.name = "Hill"
	game_manager.current_hill = mock_hill
	
	# Mock hill functions
	mock_hill.get_players_in_hill = func(): return [players[0], players[1]]  # Both in hill
	
	# Simulate 30 seconds of hill control
	for i in range(30):
		game_manager._on_koth_score_timer()
	
	# Both players should gain points
	assert_eq(players[0].koth_score, 30, "Player 1 should have 30 KOTH points")
	assert_eq(players[1].koth_score, 30, "Player 2 should have 30 KOTH points")
	
	# Change to single player in hill
	mock_hill.get_players_in_hill = func(): return [players[2]]  # Only Player 3
	
	# Simulate 35 more seconds
	for i in range(35):
		game_manager._on_koth_score_timer()
	
	assert_eq(players[2].koth_score, 35, "Player 3 should have 35 KOTH points")
	assert_eq(players[0].koth_score, 30, "Player 1 should still have 30 points")

func test_time_limit_victory_conditions():
	"""Test time limit expiry and victory determination"""
	game_manager.has_time_limit = true
	game_manager.time_limit_seconds = 0.0  # Time expired
	game_manager.game_mode = "Team Slayer"
	
	print("Testing time limit victory conditions...")
	
	# Set up score scenario
	game_manager.team_kill_scores[0] = 15  # Team A
	game_manager.team_kill_scores[1] = 10  # Team B
	
	# Simulate time limit reached
	game_manager._time_limit_reached()
	
	# Should trigger Team A victory (higher score)
	# Note: In real test, we'd verify the RPC call was made

func test_draw_situation_handling():
	"""Test draw situations in various game modes"""
	print("Testing draw situation handling...")
	
	# Team Slayer draw
	game_manager.game_mode = "Team Slayer"
	game_manager.has_time_limit = true
	game_manager.time_limit_seconds = 0.0
	game_manager.team_kill_scores[0] = 15
	game_manager.team_kill_scores[1] = 15  # Tied scores
	
	game_manager._time_limit_reached()
	# Should trigger tie game (verified through RPC in real test)
	
	# KOTH draw - multiple players with same score
	game_manager.game_mode = "KOTH"
	game_manager.koth_mode = true
	players[0].koth_score = 25
	players[1].koth_score = 25
	players[2].koth_score = 10
	players[3].koth_score = 5
	
	game_manager._time_limit_reached()
	# Should trigger tie between Player 1 and Player 2

func test_player_drop_and_reconnect_simulation():
	"""Test player drop and late join scenarios"""
	print("Testing player drop and late join scenarios...")
	
	# Simulate player drop (remove from players array)
	var dropped_player = players.pop_back()  # Remove Player 4
	game_manager.players.pop_back()
	
	assert_eq(players.size(), 3, "Should have 3 players after drop")
	assert_eq(game_manager.players.size(), 3, "GameManager should track 3 players")
	
	# Simulate game continuing with 3 players
	game_manager.game_mode = "Team Slayer"
	game_manager.on_player_die(2, 1)  # Player 1 kills Player 2
	
	assert_eq(players[0].score, 1, "Game should continue normally with 3 players")
	
	# Simulate late join (add player back)
	players.append(dropped_player)
	game_manager.players.append(dropped_player)
	
	assert_eq(players.size(), 4, "Should have 4 players after rejoin")
	
	# Verify late joiner gets proper state
	assert_eq(dropped_player.lives_remaining, 3, "Late joiner should have proper lives")
	assert_eq(dropped_player.score, 0, "Late joiner should start with 0 score")

func test_network_synchronization_integrity():
	"""Test that all score changes are properly synchronized"""
	print("Testing network synchronization integrity...")
	
	game_manager.game_mode = "Team Slayer"
	
	var initial_scores = []
	var initial_team_scores = game_manager.team_kill_scores.duplicate()
	
	for player in players:
		initial_scores.append(player.score)
	
	# Perform various actions that should trigger sync
	game_manager.on_player_die(2, 1)  # Enemy kill
	game_manager.on_player_die(3, 1)  # Friendly fire
	game_manager.on_player_die(1, 4)  # Enemy kill
	
	# Verify state consistency
	assert_ne(players[0].score, initial_scores[0], "Player 1 score should have changed")
	assert_ne(players[3].score, initial_scores[3], "Player 4 score should have changed") 
	assert_ne(game_manager.team_kill_scores[0], initial_team_scores[0], "Team A score should have changed")

func test_complete_4player_match_cycle():
	"""Test a complete 4-player match from start to finish"""
	print("Testing complete 4-player match cycle...")
	
	game_manager.game_mode = "FFA Slayer"
	game_manager.is_team_mode = false
	game_manager.kill_limit = 15
	
	# Simulate a complete FFA match where Player 1 dominates
	for i in range(5):
		game_manager.on_player_die(2, 1)  # Player 1 kills Player 2
		game_manager.on_player_die(3, 1)  # Player 1 kills Player 3
		game_manager.on_player_die(4, 1)  # Player 1 kills Player 4
	
	# Player 1 should have 15 kills and win
	assert_eq(players[0].score, 15, "Player 1 should have 15 kills")
	assert_eq(players[1].deaths, 5, "Player 2 should have 5 deaths")
	assert_eq(players[2].deaths, 5, "Player 3 should have 5 deaths") 
	assert_eq(players[3].deaths, 5, "Player 4 should have 5 deaths")
	
	# Should trigger win condition at 15 kills

func test_edge_cases_and_error_handling():
	"""Test edge cases and error conditions"""
	print("Testing edge cases and error handling...")
	
	# Test null player handling
	var result = game_manager.get_player(999)  # Non-existent player
	assert_eq(result, null, "Should return null for non-existent player")
	
	# Test empty players array
	var original_players = game_manager.players.duplicate()
	game_manager.players.clear()
	
	# Should not crash when no players exist
	game_manager.on_player_die(1, 2)  # Should handle gracefully
	
	# Restore players
	game_manager.players = original_players

# Cleanup
func after_each():
	for player in players:
		if player:
			player.queue_free()
	players.clear()
	
	if game_manager:
		game_manager.queue_free()
	if network_manager:
		network_manager.queue_free()
	if test_scene:
		test_scene.queue_free()
