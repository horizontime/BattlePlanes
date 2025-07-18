extends CharacterBody2D
class_name Player

@export var player_name : String
@export var player_id : int = 1:
	set(id):
		player_id = id
		$InputSynchronizer.set_multiplayer_authority(id)
		_set_ship_sprite() # Add this line

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
	# Calculate which ship sprite to use based on player ID
	var ship_index = (player_id - 1) % 24  # Cycle through ships 0-23
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
var weapon_heat_cool_rate : float = 25.0
var weapon_heat_cap_wait_time : float = 1.5
var weapon_heat_waiting : bool = false

# border locations for wrapping around
var border_min_x : float = -400
var border_max_x : float = 400
var border_min_y : float = -230
var border_max_y : float = 230

var game_manager

func _ready():
	game_manager = get_tree().get_current_scene().get_node("GameManager")
	game_manager.players.append(self)
	# Set the ship sprite when ready
	_set_ship_sprite()
	
	# Apply speed multiplier from game config
	_apply_speed_multiplier()
	
	# Set initial lives from game config
	if game_manager:
		if game_manager.koth_mode:
			lives_remaining = 999  # Effectively unlimited lives for KOTH
		else:
			lives_remaining = game_manager.player_lives
	
	# do we control this player?
	if $InputSynchronizer.is_multiplayer_authority():
		game_manager.local_player = self
		
		var network_manager = get_tree().get_current_scene().get_node("Network")
		set_player_name.rpc(network_manager.local_username)
	
	if multiplayer.is_server():
		position = game_manager.get_random_position()

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

# called on all CLIENTS when player shoots
@rpc("authority", "call_local", "reliable")
func play_shoot_sfx ():
	audio_player.stream = shoot_sfx
	audio_player.play()

func take_damage (damage_amount : int, attacker_player_id : int):
	cur_hp -= damage_amount
	last_attacker_id = attacker_player_id
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
	
	# In oddball mode or KOTH mode, don't lose lives
	if not game_manager.oddball_mode and not game_manager.koth_mode:
		lives_remaining -= 1
	
	is_alive = false
	position = Vector2(0, 9999)
	
	# Check if player has lives remaining (always true in oddball mode or KOTH mode)
	if lives_remaining > 0 or game_manager.oddball_mode or game_manager.koth_mode:
		respawn_timer.start(2)
		game_manager.on_player_die(player_id, last_attacker_id)
	else:
		# Player is eliminated (won't happen in oddball mode or KOTH mode)
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
	# Only respawn if player has lives remaining (always true in oddball or KOTH mode)
	if lives_remaining > 0 or game_manager.oddball_mode or game_manager.koth_mode:
		is_alive = true
		cur_hp = max_hp
		throttle = 0.0
		last_attacker_id = 0
		position = game_manager.get_random_position()
		rotation = 0

func _manage_weapon_heat (delta):
	if cur_weapon_heat < max_weapon_heat:
		cur_weapon_heat -= weapon_heat_cool_rate * delta
		
		if cur_weapon_heat < 0:
			cur_weapon_heat = 0
		
		return
	
	if weapon_heat_waiting:
		return
	
	weapon_heat_waiting = true
	await get_tree().create_timer(weapon_heat_cap_wait_time).timeout
	weapon_heat_waiting = false
	cur_weapon_heat -= weapon_heat_cool_rate * delta

# loop around when we leave the screen
func _check_border ():
	if position.x < border_min_x:
		position.x = border_max_x
	if position.x > border_max_x:
		position.x = border_min_x
	if position.y < border_min_y:
		position.y = border_max_y
	if position.y > border_max_y:
		position.y = border_min_y

func increase_score (amount : int):
	score += amount

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
