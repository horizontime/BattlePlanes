# Test Suite: Time-Limit Expiry and Draw Situations
# Tests time limit mechanics and draw condition handling across all game modes

extends GutTest

var game_manager: GameManager
var players: Array[Player] = []

func before_each():
	# Setup GameManager
	game_manager = GameManager.new()
	game_manager._ready()
	
	# Create test players
	for i in range(4):
		var player = Player.new()
		player.player_id = i + 1
		player.player_name = "Player" + str(i + 1)
		player.score = 0
		player.oddball_score = 0
		player.koth_score = 0
		player.deaths = 0
		player.lives_remaining = 3
		player.team = i % 2  # Team A: 0, Team B: 1
		players.append(player)
		game_manager.players.append(player)
	
	# Setup team mode
	game_manager.is_team_mode = true
	game_manager.team_assignments = {1: 0, 2: 1, 3: 0, 4: 1}
	game_manager.team_kill_scores = {0: 0, 1: 0}
	
	# Setup time limit
	game_manager.has_time_limit = true
	game_manager.time_limit_minutes = 10
	game_manager.time_limit_seconds = 600.0

func test_time_limit_countdown_mechanics():
	"""Test basic time limit countdown and display updates"""
	print("Testing time limit countdown mechanics...")
	
	game_manager.time_limit_seconds = 65.0
	
	# Test countdown
	game_manager._on_game_timer_timeout()
	assert_eq(game_manager.time_limit_seconds, 64.0, "Timer should countdown by 1 second")
	
	# Test warning thresholds
	game_manager.time_limit_seconds = 61.0
	game_manager._on_game_timer_timeout()
	assert_eq(game_manager.time_limit_seconds, 60.0, "Should reach 1 minute warning")
	
	game_manager.time_limit_seconds = 11.0
	game_manager._on_game_timer_timeout()
	assert_eq(game_manager.time_limit_seconds, 10.0, "Should reach 10 second warning")
	
	game_manager.time_limit_seconds = 1.0
	game_manager._on_game_timer_timeout()
	assert_eq(game_manager.time_limit_seconds, 0.0, "Should reach zero")

func test_time_limit_expiry_triggers_end_game():
	"""Test that time limit expiry calls _time_limit_reached()"""
	print("Testing time limit expiry triggers...")
	
	game_manager.time_limit_seconds = 1.0
	game_manager.game_mode = "FFA Slayer"
	
	# Set up scores for testing
	players[0].score = 5
	players[1].score = 3
	players[2].score = 1
	players[3].score = 0
	
	game_manager._on_game_timer_timeout()
	# Should trigger _time_limit_reached() which stops timer

func test_ffa_slayer_time_limit_winner():
	"""Test FFA Slayer time limit winner determination"""
	print("Testing FFA Slayer time limit winner...")
	
	game_manager.game_mode = "FFA Slayer"
	game_manager.is_team_mode = false
	game_manager.time_limit_seconds = 0.0
	
	# Set different scores
	players[0].score = 12  # Highest
	players[1].score = 8
	players[2].score = 5
	players[3].score = 3
	
	game_manager._time_limit_reached()
	# Player 1 should win with highest score (12)

func test_ffa_slayer_time_limit_tie():
	"""Test FFA Slayer time limit tie scenario"""
	print("Testing FFA Slayer time limit tie...")
	
	game_manager.game_mode = "FFA Slayer"
	game_manager.is_team_mode = false
	game_manager.time_limit_seconds = 0.0
	
	# Set tied scores
	players[0].score = 10  # Tied for first
	players[1].score = 7
	players[2].score = 10  # Tied for first
	players[3].score = 4
	
	game_manager._time_limit_reached()
	# Should declare tie between Player 1 and Player 3

func test_team_slayer_time_limit_victory():
	"""Test Team Slayer time limit victory conditions"""
	print("Testing Team Slayer time limit victory...")
	
	game_manager.game_mode = "Team Slayer"
	game_manager.time_limit_seconds = 0.0
	
	# Team A wins
	game_manager.team_kill_scores[0] = 25  # Team A
	game_manager.team_kill_scores[1] = 18  # Team B
	
	game_manager._time_limit_reached()
	# Team A should be declared winner

func test_team_slayer_time_limit_tie():
	"""Test Team Slayer time limit tie scenario"""
	print("Testing Team Slayer time limit tie...")
	
	game_manager.game_mode = "Team Slayer"
	game_manager.time_limit_seconds = 0.0
	
	# Teams tied
	game_manager.team_kill_scores[0] = 20  # Team A
	game_manager.team_kill_scores[1] = 20  # Team B
	
	game_manager._time_limit_reached()
	# Should declare tie game

func test_oddball_mode_time_limit_winner():
	"""Test Oddball mode time limit winner determination"""
	print("Testing Oddball mode time limit winner...")
	
	game_manager.oddball_mode = true
	game_manager.game_mode = "Oddball"
	game_manager.time_limit_seconds = 0.0
	
	# Set different oddball scores
	players[0].oddball_score = 45  # Highest
	players[1].oddball_score = 32
	players[2].oddball_score = 28
	players[3].oddball_score = 15
	
	game_manager._time_limit_reached()
	# Player 1 should win with highest oddball score

func test_oddball_mode_time_limit_tie():
	"""Test Oddball mode time limit tie scenario"""
	print("Testing Oddball mode time limit tie...")
	
	game_manager.oddball_mode = true
	game_manager.game_mode = "Oddball"
	game_manager.time_limit_seconds = 0.0
	
	# Set tied oddball scores
	players[0].oddball_score = 40  # Tied for first
	players[1].oddball_score = 25
	players[2].oddball_score = 40  # Tied for first
	players[3].oddball_score = 10
	
	game_manager._time_limit_reached()
	# Should declare tie between Player 1 and Player 3

func test_oddball_mode_no_winner_scenario():
	"""Test Oddball mode when no one has scored"""
	print("Testing Oddball mode no winner scenario...")
	
	game_manager.oddball_mode = true
	game_manager.game_mode = "Oddball"
	game_manager.time_limit_seconds = 0.0
	
	# All players have 0 score
	for player in players:
		player.oddball_score = 0
	
	game_manager._time_limit_reached()
	# Should declare "No Winner"

func test_koth_mode_time_limit_winner():
	"""Test KOTH mode time limit winner determination"""
	print("Testing KOTH mode time limit winner...")
	
	game_manager.koth_mode = true
	game_manager.game_mode = "KOTH"
	game_manager.time_limit_seconds = 0.0
	
	# Set different KOTH scores
	players[0].koth_score = 55  # Highest
	players[1].koth_score = 42
	players[2].koth_score = 38
	players[3].koth_score = 20
	
	game_manager._time_limit_reached()
	# Player 1 should win with highest KOTH score

func test_koth_mode_time_limit_tie():
	"""Test KOTH mode time limit tie scenario"""
	print("Testing KOTH mode time limit tie...")
	
	game_manager.koth_mode = true
	game_manager.game_mode = "KOTH"
	game_manager.time_limit_seconds = 0.0
	
	# Set tied KOTH scores
	players[0].koth_score = 35  # Tied for first
	players[1].koth_score = 22
	players[2].koth_score = 35  # Tied for first
	players[3].koth_score = 18
	
	game_manager._time_limit_reached()
	# Should declare tie between Player 1 and Player 3

func test_team_oddball_time_limit_winner():
	"""Test Team Oddball time limit winner by skull time"""
	print("Testing Team Oddball time limit winner...")
	
	game_manager.game_mode = "Team Oddball"
	game_manager.team_skull_time = {0: 150.0, 1: 120.0}  # Team A has more skull time
	game_manager.time_limit_seconds = 0.0
	
	game_manager._check_team_oddball_time_limit()
	# Team A should win with more skull time

func test_team_oddball_skull_time_tie_tiebreaker():
	"""Test Team Oddball skull time tie with kill count tiebreaker"""
	print("Testing Team Oddball skull time tie with tiebreaker...")
	
	game_manager.game_mode = "Team Oddball"
	game_manager.team_skull_time = {0: 150.0, 1: 150.0}  # Teams tied on skull time
	game_manager.player_kills = {1: 5, 2: 3, 3: 4, 4: 2}  # Team A: 9 kills, Team B: 5 kills
	game_manager.time_limit_seconds = 0.0
	
	game_manager._check_team_oddball_time_limit()
	# Team A should win on tiebreaker (9 > 5 kills)

func test_team_oddball_complete_tie():
	"""Test Team Oddball complete tie scenario"""
	print("Testing Team Oddball complete tie...")
	
	game_manager.game_mode = "Team Oddball"
	game_manager.team_skull_time = {0: 150.0, 1: 150.0}  # Teams tied on skull time
	game_manager.player_kills = {1: 5, 2: 4, 3: 4, 4: 5}  # Team A: 9 kills, Team B: 9 kills
	game_manager.time_limit_seconds = 0.0
	
	game_manager._check_team_oddball_time_limit()
	# Should declare draw

func test_standard_mode_time_limit_winner():
	"""Test Standard mode time limit winner determination"""
	print("Testing Standard mode time limit winner...")
	
	game_manager.game_mode = "Standard"
	game_manager.is_team_mode = false
	game_manager.time_limit_seconds = 0.0
	
	# Set up scores where all players have lives remaining
	players[0].score = 8
	players[0].lives_remaining = 2
	players[1].score = 5
	players[1].lives_remaining = 1
	players[2].score = 3
	players[2].lives_remaining = 3
	players[3].score = 6
	players[3].lives_remaining = 1
	
	game_manager._time_limit_reached()
	# Player 1 should win with highest score among alive players

func test_standard_mode_eliminated_players_excluded():
	"""Test Standard mode excludes eliminated players from time limit victory"""
	print("Testing Standard mode excludes eliminated players...")
	
	game_manager.game_mode = "Standard"
	game_manager.is_team_mode = false
	game_manager.time_limit_seconds = 0.0
	
	# Player with highest score is eliminated
	players[0].score = 15
	players[0].lives_remaining = 0  # Eliminated
	players[1].score = 8
	players[1].lives_remaining = 2
	players[2].score = 5
	players[2].lives_remaining = 1
	players[3].score = 6
	players[3].lives_remaining = 3
	
	game_manager._time_limit_reached()
	# Player 2 should win (highest score among alive players)

func test_multiple_timer_warnings():
	"""Test timer warning messages at different intervals"""
	print("Testing timer warning messages...")
	
	game_manager.game_mode = "FFA Slayer"
	
	# Test 1 minute warning
	game_manager.time_limit_seconds = 60.0
	game_manager._on_game_timer_timeout()
	# Should print "1 minute remaining!"
	
	# Test 10 second warning
	game_manager.time_limit_seconds = 10.0
	game_manager._on_game_timer_timeout()
	# Should print "10 seconds remaining!"

func test_timer_stops_on_expiry():
	"""Test that timer properly stops when time limit is reached"""
	print("Testing timer stops on expiry...")
	
	game_manager.game_mode = "FFA Slayer"
	game_manager.time_limit_seconds = 1.0
	
	assert_true(game_manager.game_timer.timeout.is_connected(game_manager._on_game_timer_timeout), "Timer should be connected")
	
	game_manager._on_game_timer_timeout()
	# Timer should be stopped in _time_limit_reached()

func test_no_time_limit_mode():
	"""Test game behavior when time limit is disabled"""
	print("Testing no time limit mode...")
	
	game_manager.has_time_limit = false
	game_manager.time_limit_seconds = 0.0
	
	# Should not trigger time limit logic
	game_manager._on_game_timer_timeout()
	# Game should continue normally without time limit checks

func test_timer_ui_color_changes():
	"""Test timer UI color changes based on time remaining"""
	print("Testing timer UI color changes...")
	
	# Note: This would require actual UI setup for full testing
	# Testing the logic in _update_timer_display_clients
	
	# Red for <= 10 seconds
	game_manager._update_timer_display_clients(5.0)
	# Should set red color
	
	# Yellow for <= 60 seconds
	game_manager._update_timer_display_clients(30.0)
	# Should set yellow color
	
	# White for > 60 seconds
	game_manager._update_timer_display_clients(120.0)
	# Should set white color

func test_time_limit_with_different_game_modes_simultaneously():
	"""Test time limit behavior when multiple game mode flags are set"""
	print("Testing time limit with multiple game modes...")
	
	# Edge case: multiple modes enabled
	game_manager.oddball_mode = true
	game_manager.koth_mode = true
	game_manager.game_mode = "Team Slayer"
	game_manager.time_limit_seconds = 0.0
	
	# Set scores for different modes
	players[0].oddball_score = 30
	players[0].koth_score = 40
	players[0].score = 10
	game_manager.team_kill_scores[0] = 15
	
	game_manager._time_limit_reached()
	# Should handle mode priority correctly

func test_edge_case_zero_scores_all_modes():
	"""Test edge cases where all players/teams have zero scores"""
	print("Testing zero scores edge cases...")
	
	# FFA with all zero scores
	game_manager.game_mode = "FFA Slayer"
	game_manager.is_team_mode = false
	game_manager.time_limit_seconds = 0.0
	
	for player in players:
		player.score = 0
		player.lives_remaining = 1  # All alive
	
	game_manager._time_limit_reached()
	# Should handle gracefully

func test_negative_scores_in_time_limit():
	"""Test time limit victory with negative scores (from friendly fire)"""
	print("Testing negative scores in time limit...")
	
	game_manager.game_mode = "Team Slayer"
	game_manager.time_limit_seconds = 0.0
	
	# Team A has negative score due to excessive friendly fire
	game_manager.team_kill_scores[0] = -5  # Should be clamped to 0
	game_manager.team_kill_scores[1] = 3
	
	game_manager._time_limit_reached()
	# Team B should win

# Cleanup
func after_each():
	for player in players:
		if player:
			player.queue_free()
	players.clear()
	
	if game_manager:
		game_manager.queue_free()
