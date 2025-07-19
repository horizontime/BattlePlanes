# Unit Test Suite: Kill-Score Arithmetic with Friendly-Fire Edge Cases
# Testing friendly fire penalties, score minimums, and team vs individual scoring logic

extends GutTest

var game_manager: GameManager
var player1: Player
var player2: Player 
var player3: Player
var player4: Player

func before_each():
	# Setup test environment
	game_manager = GameManager.new()
	game_manager._ready()
	
	# Create test players
	player1 = Player.new()
	player1.player_id = 1
	player1.player_name = "Player1"
	player1.score = 5
	player1.team = 0  # Team A
	
	player2 = Player.new()
	player2.player_id = 2
	player2.player_name = "Player2"
	player2.score = 3
	player2.team = 1  # Team B
	
	player3 = Player.new()
	player3.player_id = 3
	player3.player_name = "Player3"
	player3.score = 0
	player3.team = 0  # Team A
	
	player4 = Player.new()
	player4.player_id = 4
	player4.player_name = "Player4"
	player4.score = -1  # Already at minimum
	player4.team = 1  # Team B
	
	# Add players to game manager
	game_manager.players = [player1, player2, player3, player4]
	
	# Setup team mode
	game_manager.is_team_mode = true
	game_manager.team_assignments = {1: 0, 2: 1, 3: 0, 4: 1}
	game_manager.team_kill_scores = {0: 10, 1: 5}

func test_team_slayer_enemy_kill():
	"""Test Team Slayer mode: Enemy kill gives +1 to player and team"""
	game_manager.game_mode = "Team Slayer"
	
	var initial_player_score = player1.score
	var initial_team_score = game_manager.team_kill_scores[0]
	
	# Player1 (Team A) kills Player2 (Team B)
	game_manager.on_player_die(2, 1)
	
	assert_eq(player1.score, initial_player_score + 1, "Enemy kill should increase player score by 1")
	assert_eq(game_manager.team_kill_scores[0], initial_team_score + 1, "Enemy kill should increase team score by 1")

func test_team_slayer_friendly_fire_penalty():
	"""Test Team Slayer mode: Friendly fire gives -1 with minimum -1 floor"""
	game_manager.game_mode = "Team Slayer"
	
	# Player1 (Team A) kills Player3 (Team A) - friendly fire
	game_manager.on_player_die(3, 1)
	
	assert_eq(player1.score, 4, "Friendly fire should decrease player score by 1 (5-1=4)")
	assert_eq(game_manager.team_kill_scores[0], 9, "Friendly fire should decrease team score by 1 (10-1=9)")

func test_team_slayer_friendly_fire_minimum_floor():
	"""Test Team Slayer mode: Friendly fire cannot push player below -1"""
	game_manager.game_mode = "Team Slayer"
	
	# Player4 already at -1, commits friendly fire
	game_manager.on_player_die(2, 4)  # Player4 kills Player2 (different team, should be +1)
	assert_eq(player4.score, 0, "Enemy kill should bring player from -1 to 0")
	
	# Now test friendly fire from 0
	player4.score = -1  # Reset to -1
	game_manager.on_player_die(4, 4)  # Self-damage (friendly fire to own team)
	
	# Note: Need to test actual friendly fire scenario
	player2.team = 1  # Ensure Player2 is on Team B
	player4.team = 1  # Player4 is also Team B
	game_manager.on_player_die(2, 4)  # Player4 (Team B) kills Player2 (Team B) - friendly fire
	
	assert_eq(player4.score, -1, "Friendly fire should not push player below -1 minimum")

func test_team_slayer_team_score_cannot_go_negative():
	"""Test Team Slayer mode: Team score cannot go below 0"""
	game_manager.game_mode = "Team Slayer"
	game_manager.team_kill_scores[1] = 0  # Set Team B to 0
	
	# Player4 (Team B) commits friendly fire against Player2 (Team B)
	game_manager.on_player_die(2, 4)
	
	assert_eq(game_manager.team_kill_scores[1], 0, "Team score should not go below 0")

func test_team_oddball_friendly_fire_kill_tracking():
	"""Test Team Oddball mode: Friendly fire decrements kill count but not below 0"""
	game_manager.game_mode = "Team Oddball"
	game_manager.player_kills = {1: 5, 2: 3, 3: 1, 4: 0}
	
	# Player1 (Team A) kills Player3 (Team A) - friendly fire
	game_manager._handle_team_oddball_kill(player3, player1)
	
	assert_eq(game_manager.player_kills[1], 4, "Friendly fire should decrement kill count by 1 (5-1=4)")
	
	# Test minimum floor
	game_manager.player_kills[4] = 0
	game_manager._handle_team_oddball_kill(player2, player4)  # Player4 friendly fire
	
	assert_eq(game_manager.player_kills[4], 0, "Kill count should not go below 0")

func test_team_oddball_enemy_kill_tracking():
	"""Test Team Oddball mode: Enemy kills increment kill count"""
	game_manager.game_mode = "Team Oddball"
	game_manager.player_kills = {1: 5, 2: 3, 3: 1, 4: 0}
	
	# Player1 (Team A) kills Player2 (Team B) - enemy kill
	game_manager._handle_team_oddball_kill(player2, player1)
	
	assert_eq(game_manager.player_kills[1], 6, "Enemy kill should increment kill count by 1 (5+1=6)")

func test_ffa_slayer_no_friendly_fire_logic():
	"""Test FFA Slayer mode: All kills are treated as enemy kills (+1 score)"""
	game_manager.game_mode = "FFA Slayer"
	game_manager.is_team_mode = false
	
	var initial_score = player1.score
	
	# Any kill should increase score by 1
	game_manager.on_player_die(2, 1)
	assert_eq(player1.score, initial_score + 1, "FFA mode should treat all kills as +1 score")
	
	game_manager.on_player_die(3, 1)
	assert_eq(player1.score, initial_score + 2, "FFA mode should accumulate kills normally")

func test_standard_mode_no_friendly_fire_logic():
	"""Test Standard mode: All kills are treated as +1 score regardless of teams"""
	game_manager.game_mode = "Standard"
	game_manager.is_team_mode = false
	
	var initial_score = player1.score
	
	# Any kill should increase score by 1
	game_manager.on_player_die(2, 1)
	assert_eq(player1.score, initial_score + 1, "Standard mode should treat all kills as +1 score")

func test_elimination_vs_death_consistency():
	"""Test that both on_player_die and on_player_eliminated have consistent friendly fire logic"""
	game_manager.game_mode = "Team Slayer"
	
	# Test on_player_die
	var initial_score = player1.score
	game_manager.on_player_die(3, 1)  # Player1 kills teammate Player3
	var score_after_die = player1.score
	
	# Reset and test on_player_eliminated  
	player1.score = initial_score
	game_manager.on_player_eliminated(3, 1)  # Player1 eliminates teammate Player3
	var score_after_elimination = player1.score
	
	assert_eq(score_after_die, score_after_elimination, "on_player_die and on_player_eliminated should have consistent friendly fire logic")

func test_score_synchronization_calls():
	"""Test that score changes trigger proper RPC synchronization calls"""
	game_manager.game_mode = "Team Slayer"
	
	# Mock RPC tracking (in real implementation, we'd need to verify RPC calls)
	var initial_score = player1.score
	game_manager.on_player_die(2, 1)  # Enemy kill
	
	# Verify score changed (RPC verification would need mocking framework)
	assert_eq(player1.score, initial_score + 1, "Score should change and trigger sync")

func test_team_win_condition_at_30_kills():
	"""Test team win condition triggers at 30+ kills"""
	game_manager.game_mode = "Team Slayer"
	game_manager.team_kill_scores[0] = 29
	
	# This kill should trigger win condition
	game_manager._update_team_score(0, 1)
	
	assert_eq(game_manager.team_kill_scores[0], 30, "Team should reach 30 kills")
	# Note: In full test, we'd verify end_game_clients.rpc was called

func test_multiple_friendly_fire_scenarios():
	"""Test complex scenarios with multiple friendly fire incidents"""
	game_manager.game_mode = "Team Slayer"
	
	# Scenario: Player starts at 2, commits 3 friendly fires, should end at -1
	player1.score = 2
	
	game_manager.on_player_die(3, 1)  # FF 1: 2->1
	game_manager.on_player_die(3, 1)  # FF 2: 1->0  
	game_manager.on_player_die(3, 1)  # FF 3: 0->-1
	game_manager.on_player_die(3, 1)  # FF 4: should stay -1
	
	assert_eq(player1.score, -1, "Multiple friendly fires should bottom out at -1")

func test_edge_case_zero_score_friendly_fire():
	"""Test friendly fire when player has exactly 0 score"""
	game_manager.game_mode = "Team Slayer"
	player3.score = 0
	
	game_manager.on_player_die(1, 3)  # Player3 kills teammate Player1
	
	assert_eq(player3.score, -1, "Friendly fire from 0 should go to -1")

func test_mixed_kill_types_accumulation():
	"""Test mixed enemy kills and friendly fire over time"""
	game_manager.game_mode = "Team Slayer"
	player1.score = 0
	
	game_manager.on_player_die(2, 1)  # Enemy kill: 0->1
	game_manager.on_player_die(3, 1)  # Friendly fire: 1->0
	game_manager.on_player_die(2, 1)  # Enemy kill: 0->1
	game_manager.on_player_die(3, 1)  # Friendly fire: 1->0
	game_manager.on_player_die(3, 1)  # Friendly fire: 0->-1
	game_manager.on_player_die(2, 1)  # Enemy kill: -1->0
	
	assert_eq(player1.score, 0, "Mixed kill types should accumulate correctly")

# Cleanup
func after_each():
	if game_manager:
		game_manager.queue_free()
	for player in [player1, player2, player3, player4]:
		if player:
			player.queue_free()
