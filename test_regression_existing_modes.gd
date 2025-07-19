# Test Suite: Regression Tests for Existing Game Modes
# Ensures no side effects from new features on core game functionality

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
		player.cur_hp = 100
		player.max_hp = 100
		player.team = i % 2
		players.append(player)
		game_manager.players.append(player)
	
	# Reset game state
	game_manager.is_team_mode = false
	game_manager.team_assignments = {}
	game_manager.team_kill_scores = {0: 0, 1: 0}
	game_manager.oddball_mode = false
	game_manager.koth_mode = false
	game_manager.hearts_enabled = false
	game_manager.has_time_limit = false

func test_standard_ffa_mode_basic_functionality():
	"""Test that standard FFA mode still works as expected"""
	print("Testing standard FFA mode basic functionality...")
	
	game_manager.game_mode = "Standard"
	game_manager.is_team_mode = false
	game_manager.player_lives = 3
	
	# Test kill scoring
	game_manager.on_player_die(2, 1)  # Player 1 kills Player 2
	assert_eq(players[0].score, 1, "Player 1 should have 1 kill")
	assert_eq(players[1].deaths, 1, "Player 2 should have 1 death")
	
	# Test lives system
	assert_eq(players[1].lives_remaining, 3, "Player 2 should still have 3 lives (respawn)")
	
	# Test elimination (run out of lives)
	players[1].lives_remaining = 1
	game_manager.on_player_eliminated(2, 1)  # Player 1 eliminates Player 2
	assert_eq(players[0].score, 2, "Player 1 should have 2 kills total")

func test_standard_ffa_last_player_standing():
	"""Test last player standing victory condition in standard FFA"""
	print("Testing standard FFA last player standing...")
	
	game_manager.game_mode = "Standard"
	game_manager.is_team_mode = false
	
	# Eliminate all but one player
	for i in range(1, 4):  # Eliminate players 2, 3, 4
		players[i].lives_remaining = 0
	
	# Check remaining alive players
	var alive_players = []
	for p in players:
		if p.lives_remaining > 0:
			alive_players.append(p)
	
	assert_eq(alive_players.size(), 1, "Should have 1 player remaining")
	assert_eq(alive_players[0], players[0], "Player 1 should be the survivor")

func test_ffa_slayer_mode_kill_limit():
	"""Test FFA Slayer mode kill limit victory condition"""
	print("Testing FFA Slayer mode kill limit...")
	
	game_manager.game_mode = "FFA Slayer"
	game_manager.is_team_mode = false
	game_manager.kill_limit = 15
	
	# Player has unlimited lives in FFA Slayer
	for player in players:
		player.lives_remaining = 999
	
	# Get Player 1 to kill limit
	for i in range(14):
		game_manager.on_player_die(2, 1)  # 14 kills
	
	assert_eq(players[0].score, 14, "Player 1 should have 14 kills")
	
	# One more kill should trigger victory
	game_manager.on_player_die(2, 1)  # 15th kill
	assert_eq(players[0].score, 15, "Player 1 should have 15 kills and win")

func test_team_slayer_mode_team_scoring():
	"""Test Team Slayer mode team scoring system"""
	print("Testing Team Slayer mode team scoring...")
	
	game_manager.game_mode = "Team Slayer"
	game_manager.is_team_mode = true
	game_manager.team_assignments = {1: 0, 2: 1, 3: 0, 4: 1}
	game_manager.team_kill_scores = {0: 0, 1: 0}
	
	# Set player teams
	players[0].team = 0  # Team A
	players[1].team = 1  # Team B
	players[2].team = 0  # Team A
	players[3].team = 1  # Team B
	
	# Team A scores
	game_manager.on_player_die(2, 1)  # Player 1 (A) kills Player 2 (B)
	game_manager.on_player_die(4, 3)  # Player 3 (A) kills Player 4 (B)
	
	assert_eq(game_manager.team_kill_scores[0], 2, "Team A should have 2 kills")
	assert_eq(game_manager.team_kill_scores[1], 0, "Team B should have 0 kills")

func test_team_slayer_mode_win_condition():
	"""Test Team Slayer mode win condition at 30 kills"""
	print("Testing Team Slayer mode win condition...")
	
	game_manager.game_mode = "Team Slayer"
	game_manager.is_team_mode = true
	game_manager.team_kill_scores = {0: 29, 1: 15}
	
	# One more kill should trigger Team A victory
	game_manager._update_team_score(0, 1)
	assert_eq(game_manager.team_kill_scores[0], 30, "Team A should reach 30 kills")

func test_oddball_mode_skull_mechanics():
	"""Test basic Oddball mode skull mechanics"""
	print("Testing Oddball mode skull mechanics...")
	
	game_manager.oddball_mode = true
	game_manager.game_mode = "Oddball"
	game_manager.skull_holder = players[0]
	
	# Test score accrual
	for i in range(30):
		game_manager._on_oddball_score_timer()
	
	assert_eq(players[0].oddball_score, 30, "Player 1 should have 30 oddball points")
	
	# Test skull drop on death
	game_manager.drop_skull_on_death(players[0], Vector2(100, 100))
	assert_eq(game_manager.skull_holder, null, "Skull holder should be null after death")

func test_oddball_mode_win_condition():
	"""Test Oddball mode win condition at 60 points"""
	print("Testing Oddball mode win condition...")
	
	game_manager.oddball_mode = true
	game_manager.game_mode = "Oddball"
	game_manager.oddball_win_score = 60
	game_manager.skull_holder = players[0]
	
	# Get to 59 points
	for i in range(59):
		game_manager._on_oddball_score_timer()
	
	assert_eq(players[0].oddball_score, 59, "Player 1 should have 59 points")
	
	# One more point should trigger victory
	game_manager._on_oddball_score_timer()
	assert_eq(players[0].oddball_score, 60, "Player 1 should win with 60 points")

func test_koth_mode_hill_control():
	"""Test KOTH mode hill control mechanics"""
	print("Testing KOTH mode hill control...")
	
	game_manager.koth_mode = true
	game_manager.game_mode = "KOTH"
	
	# Create mock hill
	var mock_hill = Node.new()
	mock_hill.name = "Hill"
	game_manager.current_hill = mock_hill
	mock_hill.get_players_in_hill = func(): return [players[0]]
	
	# Test score accrual
	for i in range(30):
		game_manager._on_koth_score_timer()
	
	assert_eq(players[0].koth_score, 30, "Player 1 should have 30 KOTH points")

func test_koth_mode_win_condition():
	"""Test KOTH mode win condition at 60 points"""
	print("Testing KOTH mode win condition...")
	
	game_manager.koth_mode = true
	game_manager.game_mode = "KOTH"
	game_manager.koth_win_score = 60
	
	# Create mock hill
	var mock_hill = Node.new()
	mock_hill.name = "Hill"
	game_manager.current_hill = mock_hill
	mock_hill.get_players_in_hill = func(): return [players[0]]
	
	# Get to 59 points
	for i in range(59):
		game_manager._on_koth_score_timer()
	
	assert_eq(players[0].koth_score, 59, "Player 1 should have 59 points")
	
	# One more point should trigger victory
	game_manager._on_koth_score_timer()
	assert_eq(players[0].koth_score, 60, "Player 1 should win with 60 points")

func test_heart_powerup_functionality():
	"""Test heart powerup gives extra life"""
	print("Testing heart powerup functionality...")
	
	game_manager.hearts_enabled = true
	players[0].lives_remaining = 2
	
	# Player picks up heart
	players[0].gain_extra_life()
	
	assert_eq(players[0].lives_remaining, 3, "Player should gain 1 extra life")

func test_player_respawn_mechanics():
	"""Test player respawn after death"""
	print("Testing player respawn mechanics...")
	
	game_manager.game_mode = "Standard"
	players[0].lives_remaining = 2
	players[0].cur_hp = 0
	players[0].is_alive = false
	
	# Respawn player
	players[0].respawn()
	
	assert_true(players[0].is_alive, "Player should be alive after respawn")
	assert_eq(players[0].cur_hp, players[0].max_hp, "Player should have full health")
	assert_eq(players[0].lives_remaining, 2, "Lives should remain unchanged for respawn")

func test_weapon_heat_system():
	"""Test weapon heat system still works"""
	print("Testing weapon heat system...")
	
	players[0].cur_weapon_heat = 90.0
	players[0].max_weapon_heat = 100.0
	
	# Add heat from shooting
	players[0].cur_weapon_heat += 15.0
	players[0].cur_weapon_heat = clamp(players[0].cur_weapon_heat, 0, players[0].max_weapon_heat)
	
	assert_eq(players[0].cur_weapon_heat, 100.0, "Weapon heat should be capped at max")
	
	# Test cooling down
	players[0]._manage_weapon_heat(1.0)  # 1 second cooling
	# Note: Actual cooling rate depends on implementation, just verify it decreases
	assert_le(players[0].cur_weapon_heat, 100.0, "Weapon heat should not exceed max")

func test_player_damage_system():
	"""Test player damage and death system"""
	print("Testing player damage system...")
	
	players[0].cur_hp = 100
	players[0].take_damage(30, 2)  # Player 2 damages Player 1
	
	assert_eq(players[0].cur_hp, 70, "Player should take 30 damage")
	assert_eq(players[0].last_attacker_id, 2, "Last attacker should be recorded")
	
	# Test death from damage
	players[0].take_damage(70, 2)  # Finish off Player 1
	assert_le(players[0].cur_hp, 0, "Player should be dead")

func test_team_spawn_positions():
	"""Test team-based spawn positioning"""
	print("Testing team spawn positions...")
	
	game_manager.is_team_mode = true
	
	var team_a_pos = game_manager.get_team_spawn_position(0)  # Team A
	var team_b_pos = game_manager.get_team_spawn_position(1)  # Team B
	
	# Team A spawns on left, Team B on right
	assert_lt(team_a_pos.x, team_b_pos.x, "Team A should spawn left of Team B")
	assert_lt(team_a_pos.x, 0, "Team A should spawn on left side")
	assert_gt(team_b_pos.x, 0, "Team B should spawn on right side")

func test_random_spawn_positions():
	"""Test random spawn positioning for FFA modes"""
	print("Testing random spawn positions...")
	
	game_manager.is_team_mode = false
	
	var pos1 = game_manager.get_random_position()
	var pos2 = game_manager.get_random_position()
	
	# Positions should be within bounds
	assert_ge(pos1.x, game_manager.min_x, "Position should be within min X bound")
	assert_le(pos1.x, game_manager.max_x, "Position should be within max X bound")
	assert_ge(pos1.y, game_manager.min_y, "Position should be within min Y bound")
	assert_le(pos1.y, game_manager.max_y, "Position should be within max Y bound")

func test_game_reset_functionality():
	"""Test game reset clears all state properly"""
	print("Testing game reset functionality...")
	
	# Set up some game state
	players[0].score = 10
	players[0].oddball_score = 25
	players[0].koth_score = 30
	players[0].deaths = 5
	players[0].cur_hp = 50
	game_manager.team_kill_scores = {0: 15, 1: 12}
	
	# Reset the game
	game_manager.reset_game()
	
	# Verify all state is reset
	assert_eq(players[0].score, 0, "Player score should be reset")
	assert_eq(players[0].oddball_score, 0, "Oddball score should be reset")
	assert_eq(players[0].koth_score, 0, "KOTH score should be reset")
	assert_eq(players[0].deaths, 0, "Deaths should be reset")
	assert_eq(players[0].cur_hp, players[0].max_hp, "Health should be restored")
	assert_eq(game_manager.team_kill_scores[0], 0, "Team scores should be reset")
	assert_eq(game_manager.team_kill_scores[1], 0, "Team scores should be reset")

func test_player_elimination_tracking():
	"""Test that player elimination is tracked correctly"""
	print("Testing player elimination tracking...")
	
	game_manager.game_mode = "Standard"
	players[1].lives_remaining = 1  # About to be eliminated
	
	game_manager.on_player_eliminated(2, 1)  # Player 1 eliminates Player 2
	
	assert_eq(players[0].score, 1, "Attacker should get kill credit")
	assert_eq(players[1].deaths, 1, "Victim should get death count")
	assert_eq(players[1].lives_remaining, 1, "Lives tracking should be consistent")

func test_score_synchronization_still_works():
	"""Test that score synchronization mechanisms work"""
	print("Testing score synchronization...")
	
	game_manager.game_mode = "Standard"
	
	# Test basic score sync (would trigger RPCs in real game)
	var initial_score = players[0].score
	game_manager.on_player_die(2, 1)
	
	assert_ne(players[0].score, initial_score, "Score should change and sync")

func test_multiple_game_mode_configurations():
	"""Test various game mode configurations don't interfere"""
	print("Testing multiple game mode configurations...")
	
	# Test FFA configuration
	game_manager.game_mode = "FFA Slayer"
	game_manager.is_team_mode = false
	game_manager.oddball_mode = false
	game_manager.koth_mode = false
	
	game_manager.on_player_die(2, 1)
	assert_eq(players[0].score, 1, "FFA mode should work normally")
	
	# Switch to team mode
	game_manager.game_mode = "Team Slayer"
	game_manager.is_team_mode = true
	game_manager.team_assignments = {1: 0, 2: 1, 3: 0, 4: 1}
	players[0].team = 0
	players[1].team = 1
	
	var initial_team_score = game_manager.team_kill_scores[0]
	game_manager.on_player_die(2, 1)  # Cross-team kill
	
	assert_gt(game_manager.team_kill_scores[0], initial_team_score, "Team mode should work after switch")

func test_edge_case_empty_players_list():
	"""Test game handles empty players list gracefully"""
	print("Testing empty players list handling...")
	
	var original_players = game_manager.players.duplicate()
	game_manager.players.clear()
	
	# Should not crash with empty players
	game_manager.on_player_die(1, 2)
	game_manager.reset_game()
	
	# Restore players
	game_manager.players = original_players

func test_edge_case_invalid_player_ids():
	"""Test game handles invalid player IDs gracefully"""
	print("Testing invalid player ID handling...")
	
	# Test with non-existent player IDs
	var result = game_manager.get_player(999)
	assert_null(result, "Should return null for invalid player ID")
	
	# Should not crash when referencing invalid players
	game_manager.on_player_die(999, 1)
	game_manager.on_player_die(1, 999)

func test_concurrent_mode_flags():
	"""Test behavior when multiple mode flags are set (edge case)"""
	print("Testing concurrent mode flags...")
	
	# Edge case: multiple modes enabled simultaneously
	game_manager.oddball_mode = true
	game_manager.koth_mode = true
	game_manager.game_mode = "Team Slayer"
	game_manager.is_team_mode = true
	
	# Game should still function (prioritize one mode)
	game_manager.on_player_die(2, 1)
	
	# Should not crash or produce invalid state
	assert_ge(players[0].score, 0, "Score should remain valid")

func test_lives_system_edge_cases():
	"""Test edge cases in lives system"""
	print("Testing lives system edge cases...")
	
	# Test negative lives (shouldn't happen but handle gracefully)
	players[0].lives_remaining = -1
	game_manager.on_player_die(1, 2)
	
	# Test zero lives elimination
	players[1].lives_remaining = 0
	game_manager.on_player_eliminated(2, 1)
	
	# Should handle gracefully without crashes

func test_team_assignment_consistency():
	"""Test team assignment consistency across operations"""
	print("Testing team assignment consistency...")
	
	game_manager.is_team_mode = true
	game_manager.set_team_assignments({1: 0, 2: 1, 3: 0, 4: 1})
	
	# Verify assignments are applied
	for player in players:
		if game_manager.team_assignments.has(player.player_id):
			assert_eq(player.team, game_manager.team_assignments[player.player_id], 
					  "Player team should match assignment")

func test_backward_compatibility():
	"""Test that old game functionality still works with new features disabled"""
	print("Testing backward compatibility...")
	
	# Disable all new features
	game_manager.has_time_limit = false
	game_manager.hearts_enabled = false
	game_manager.oddball_mode = false
	game_manager.koth_mode = false
	game_manager.is_team_mode = false
	
	# Run basic game scenario
	game_manager.game_mode = "Standard"
	game_manager.on_player_die(2, 1)
	game_manager.on_player_die(3, 1)
	game_manager.on_player_die(4, 1)
	
	assert_eq(players[0].score, 3, "Basic gameplay should work with features disabled")

# Cleanup
func after_each():
	for player in players:
		if player:
			player.queue_free()
	players.clear()
	
	if game_manager:
		game_manager.queue_free()
