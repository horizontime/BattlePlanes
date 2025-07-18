extends CharacterBody2D
class_name Player

@export var player_name : String
@export var player_id : int = 1:
	set(id):
		player_id = id
		$InputSynchronizer.set_multiplayer_authority(id)
		# Server has authority over player position and state
		$PlayerSynchronizer.set_multiplayer_authority(1)  # Server is always ID 1
		_set_ship_sprite() # Add this line

# Team assignment (0 = Team A, 1 = Team B, -1 = no team/FFA)
@export var team : int = -1:
	set(new_team):
		team = new_team
		_set_ship_sprite()

@export var base_max_speed : float = 150.0  # Base speed before multiplier
@export var max_speed : float = 150.0  # Actual speed with multiplier applied
@export var turn_rate : float = 2.5
@export var acceleration_rate : float = 3.0  # How quickly the plane speeds up when accelerating
@export var deceleration_rate : float = 2.0  # How quickly the plane slows down when not accelerating
var throttle : float = 0.0

@export var shoot_rate : float = 0.1
var last_shoot_time : float
var projectile_scene = preload("res://Scenes/Projectile.tscn")

@export var cur_hp : int = 100
@export var max_hp : int = 100
@export var score : int = 0
@export var oddball_score : int = 0
@export var koth_score : int = 0
@export var deaths : int = 0
@export var lives_remaining : int = 3
var last_attacker_id : int
var is_alive : bool = true

# Health bar reference
var health_bar : HealthBar = null

@onready var input = $InputSynchronizer
@onready var shadow = $Shadow
@onready var muzzle = $Muzzle
@onready var respawn_timer = $RespawnTimer
@onready var audio_player = $AudioPlayer
@onready var sprite = $Sprite
@onready var hit_particle = $HitParticle

# Add this new function
func _set_ship_sprite():
	var ship_index = 0  # Default to ship_0000.png
	
	if team >= 0:
		# Team mode: Team A (0) uses ship_0000.png, Team B (1) uses ship_0001.png
		ship_index = team
	else:
		# Non-team mode: use variety based on player ID
		ship_index = (player_id - 1) % 24  # Cycle through ships 0-23
	
	var ship_texture_path = "res://Sprites/Ships/ship_%04d.png" % ship_index
	
	# Load the texture
	var ship_texture = load(ship_texture_path)
	
	# Apply to both sprite and shadow
	if sprite:
		sprite.texture = ship_texture
	if shadow:
		shadow.texture = ship_texture
		

# sound effects
var shoot_sfx = preload("res://Audio/PlaneShoot.wav")
var hit_sfx = preload("res://Audio/PlaneHit.wav")
var explode_sfx = preload("res://Audio/PlaneExplode.wav")

# weapon heat
@export var cur_weapon_heat : float = 0.0
@export var max_weapon_heat : float = 100.0
var weapon_heat_increase_rate : float = 7.0
var weapon_heat_cool_rate : float = 37.5
var weapon_heat_cap_wait_time : float = 1.5
var weapon_heat_waiting : bool = false

# Prevent immediate pickups (e.g., Oddball skull) right after spawn
var _pickup_immunity_until_ms : int = 0  # game ticks in milliseconds until which pickup is disallowed

func can_pickup_items() -> bool:
	return Time.get_ticks_msec() >= _pickup_immunity_until_ms

# NEW: sync weapon heat to clients
@rpc("reliable")
func _sync_weapon_heat(new_heat: float):
	# Server sends weapon heat updates; clients receive
	if not multiplayer.is_server():
		cur_weapon_heat = new_heat

# border locations for wrapping around
var border_min_x : float = -400
var border_max_x : float = 400
var border_min_y : float = -230
var border_max_y : float = 230

var game_manager

func _ready():
	game_manager = get_tree().get_current_scene().get_node("GameManager")
	game_manager.players.append(self)
	
	# Set team assignment if in team mode
	if game_manager.is_team_mode:
		if game_manager.team_assignments.has(player_id):
			team = game_manager.team_assignments[player_id]
		else:
			# Auto-assign for mid-match joins
			team = game_manager._auto_assign_team(player_id)
	
	# Set the ship sprite when ready (after team assignment)
	_set_ship_sprite()
	
	# Apply speed multiplier from game config
	_apply_speed_multiplier()
	
	# Set initial lives from game config
	if game_manager:
		if game_manager.koth_mode or game_manager.game_mode == "FFA Slayer":
			lives_remaining = 999  # Effectively unlimited lives for KOTH and FFA Slayer
		else:
			lives_remaining = game_manager.player_lives
	
	# do we control this player?
	if $InputSynchronizer.is_multiplayer_authority():
		game_manager.local_player = self
		
		var network_manager = get_tree().get_current_scene().get_node("Network")
		set_player_name.rpc(network_manager.local_username)
	
	if multiplayer.is_server():
		# Assign spawn position based on team mode
		if game_manager.is_team_mode and team >= 0:
			position = game_manager.get_team_spawn_position(team)
		else:
			position = game_manager.get_random_position()
		rotation = randf() * 2 * PI  # Random initial rotation

		# Set a short immunity period where pickups are disabled
		_pickup_immunity_until_ms = Time.get_ticks_msec() + 500  # 0.5 seconds

		# Small delay to ensure multiplayer authority is fully set before syncing state
		await get_tree().process_frame
		# Re-sync position in case any network interpolation occurred during the first frame
		_sync_respawn_state.rpc(position, rotation)
		sprite.visible = true  # Ensure sprite is visible on spawn
		print("Player %d spawned at position: %s, rotation: %s" % [player_id, position, rotation])
		
		# Initial spawn state already synced above after authority confirmation

func _apply_speed_multiplier():
	"""Apply the speed multiplier from game configuration"""
	if game_manager:
		max_speed = base_max_speed * game_manager.speed_multiplier

@rpc("any_peer", "call_local", "reliable")
func set_player_name (new_name : String):
	player_name = new_name

func _process(delta):
	# update shadow on all CLIENTS
	shadow.global_position = position + Vector2(0, 20)
	
	# only the server runs this code
	if multiplayer.is_server() and is_alive:
		_check_border()
		_try_shoot()
		_manage_weapon_heat(delta)

func _physics_process (delta):
	# only the server runs this code
	if multiplayer.is_server() and is_alive:
		_move(delta)

func _move (delta):
	rotate(input.turn_input * turn_rate * delta)
	
	# Handle throttle with acceleration and deceleration
	if input.throttle_input > 0:
		# Accelerating forward
		throttle += input.throttle_input * acceleration_rate * delta
	else:
		# Decelerating when no forward input (or when pressing reverse)
		throttle -= deceleration_rate * delta
	
	throttle = clamp(throttle, 0.0, 1.0)
	
	velocity = -transform.y * throttle * max_speed
	
	move_and_slide()
	
	# Force position and rotation sync for all clients
	if velocity.length() > 0 or abs(input.turn_input) > 0:
		_sync_transform.rpc(position, rotation)

func _try_shoot ():
	if not input.shoot_input:
		return
	
	if cur_weapon_heat >= max_weapon_heat:
		return
	
	if Time.get_unix_time_from_system() - last_shoot_time < shoot_rate:
		return
	
	last_shoot_time = Time.get_unix_time_from_system()
	
	var proj = projectile_scene.instantiate()
	proj.position = muzzle.global_position
	proj.rotation = rotation + deg_to_rad(randf_range(-2, 2))
	proj.owner_id = player_id
	get_tree().get_current_scene().get_node("Network/SpawnedNodes").add_child(proj, true)
	
	play_shoot_sfx.rpc()
	
	cur_weapon_heat += weapon_heat_increase_rate
	cur_weapon_heat = clamp(cur_weapon_heat, 0, max_weapon_heat)
	# NEW: send updated heat to all clients
	_sync_weapon_heat.rpc(cur_weapon_heat)

# called on all CLIENTS when player shoots
@rpc("authority", "call_local", "reliable")
func play_shoot_sfx ():
	audio_player.stream = shoot_sfx
	audio_player.play()

func take_damage (damage_amount : int, attacker_player_id : int):
	cur_hp -= damage_amount
	last_attacker_id = attacker_player_id
	# Sync health to all clients immediately
	_sync_health.rpc(cur_hp)
	take_damage_clients.rpc()
	
	if cur_hp <= 0:
		die()

# called on all CLIENTS when player takes damage
@rpc("authority", "call_local", "reliable")
func take_damage_clients ():
	if $InputSynchronizer.is_multiplayer_authority():
		game_manager.camera_shake.shake(0.1, 3.0)
	
	audio_player.stream = hit_sfx
	audio_player.play()
	
	hit_particle.emitting = true
	
	sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.05).timeout
	sprite.modulate = Color(1, 1, 1)

func die ():
	# Drop skull if holding it in oddball mode
	game_manager.drop_skull_on_death(self)
	
	# Always increment deaths counter
	deaths += 1
	
	# In oddball mode, KOTH mode, or FFA Slayer mode, don't lose lives
	if not game_manager.oddball_mode and not game_manager.koth_mode and game_manager.game_mode != "FFA Slayer":
		lives_remaining -= 1
	
	is_alive = false
	position = Vector2(0, 9999)
	sprite.visible = false  # Hide sprite on server too
	
	# Sync death state to all clients
	_sync_death_state.rpc()
	
	# Check if player has lives remaining (always true in oddball mode, KOTH mode, or FFA Slayer mode)
	if lives_remaining > 0 or game_manager.oddball_mode or game_manager.koth_mode or game_manager.game_mode == "FFA Slayer":
		respawn_timer.start(2)
		game_manager.on_player_die(player_id, last_attacker_id)
	else:
		# Player is eliminated (won't happen in oddball mode, KOTH mode, or FFA Slayer mode)
		game_manager.on_player_eliminated(player_id, last_attacker_id)
	
	die_clients.rpc()

# called on ALL clients when player dies
@rpc("authority", "call_local", "reliable")
func die_clients ():
	if $InputSynchronizer.is_multiplayer_authority():
		game_manager.camera_shake.shake(0.5, 7.0)
	
	audio_player.stream = explode_sfx
	audio_player.play()

func respawn ():
	# Only respawn if player has lives remaining (always true in oddball, KOTH, or FFA Slayer mode)
	if lives_remaining > 0 or game_manager.oddball_mode or game_manager.koth_mode or game_manager.game_mode == "FFA Slayer":
		is_alive = true
		cur_hp = max_hp
		throttle = 0.0
		last_attacker_id = 0
		# Use team spawn if in team mode, otherwise random spawn
		if game_manager.is_team_mode and team >= 0:
			position = game_manager.get_team_spawn_position(team)
		else:
			position = game_manager.get_random_position()
		rotation = randf() * 2 * PI  # Random respawn rotation
		sprite.visible = true  # Show sprite on server
		
		# Disallow pickups briefly after respawn
		_pickup_immunity_until_ms = Time.get_ticks_msec() + 500  # 0.5 seconds

		# Sync respawn state and health to all clients
		_sync_respawn_state.rpc(position, rotation)
		_sync_health.rpc(cur_hp)

func _manage_weapon_heat (delta):
	if cur_weapon_heat < max_weapon_heat:
		cur_weapon_heat -= weapon_heat_cool_rate * delta
		
		if cur_weapon_heat < 0:
			cur_weapon_heat = 0

		# NEW: update clients with cooled heat value
		_sync_weapon_heat.rpc(cur_weapon_heat)
		return
	
	if weapon_heat_waiting:
		return
	
	weapon_heat_waiting = true
	await get_tree().create_timer(weapon_heat_cap_wait_time).timeout
	weapon_heat_waiting = false
	cur_weapon_heat -= weapon_heat_cool_rate * delta
	# NEW: send heat update after waiting period as well
	_sync_weapon_heat.rpc(cur_weapon_heat)

# loop around when we leave the screen
func _check_border ():
	var wrapped = false
	if position.x < border_min_x:
		position.x = border_max_x
		wrapped = true
	if position.x > border_max_x:
		position.x = border_min_x
		wrapped = true
	if position.y < border_min_y:
		position.y = border_max_y
		wrapped = true
	if position.y > border_max_y:
		position.y = border_min_y
		wrapped = true
	
	# Sync position if player wrapped around
	if wrapped:
		_sync_transform.rpc(position, rotation)

func increase_score (amount : int):
	score += amount

@rpc("reliable")
func _sync_transform(new_position: Vector2, new_rotation: float):
	if not multiplayer.is_server():
		position = new_position
		rotation = new_rotation

@rpc("reliable")
func _sync_death_state():
	if not multiplayer.is_server():
		is_alive = false
		position = Vector2(0, 9999)
		# Hide sprite visually on death
		sprite.visible = false

@rpc("reliable")
func _sync_respawn_state(new_position: Vector2, new_rotation: float):
	if not multiplayer.is_server():
		is_alive = true
		position = new_position
		rotation = new_rotation
		sprite.visible = true  # Show sprite on respawn

@rpc("reliable")
func _sync_health(new_hp: int):
	if not multiplayer.is_server():
		cur_hp = new_hp

func gain_extra_life():
	"""Called when player gains an extra life from a heart"""
	lives_remaining += 1
	print(player_name + " gained an extra life! (Total: " + str(lives_remaining) + ")")

# Health bar management functions
func set_health_bar(bar: HealthBar):
	health_bar = bar
	if health_bar:
		health_bar.set_target_player(self)

func get_health_percentage() -> float:
	return float(cur_hp) / float(max_hp) * 100.0
