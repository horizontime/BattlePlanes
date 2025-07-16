extends Control
class_name ServerConfig

# UI References - Custom Tab
@onready var lives_spinbox = $VBoxContainer/TabContainer/Custom/CustomVBox/LivesContainer/LivesSpinBox
@onready var max_players_spinbox = $VBoxContainer/TabContainer/Custom/CustomVBox/MaxPlayersContainer/MaxPlayersSpinBox
@onready var speed_slider = $VBoxContainer/TabContainer/Custom/CustomVBox/SpeedContainer/SpeedSlider
@onready var speed_value_label = $VBoxContainer/TabContainer/Custom/CustomVBox/SpeedContainer/SpeedValueLabel
@onready var damage_slider = $VBoxContainer/TabContainer/Custom/CustomVBox/DamageContainer/DamageSlider
@onready var damage_value_label = $VBoxContainer/TabContainer/Custom/CustomVBox/DamageContainer/DamageValueLabel
@onready var time_limit_checkbox = $VBoxContainer/TabContainer/Custom/CustomVBox/TimeLimitContainer/TimeLimitCheckBox
@onready var time_limit_spinbox = $VBoxContainer/TabContainer/Custom/CustomVBox/TimeLimitContainer/TimeLimitSpinBox
@onready var hearts_checkbox = $VBoxContainer/TabContainer/Custom/CustomVBox/HeartsContainer/HeartsCheckBox
@onready var clouds_checkbox = $VBoxContainer/TabContainer/Custom/CustomVBox/CloudsContainer/CloudsCheckBox

# UI References - Free-for-all Tab
@onready var classic_deathmatch_btn = $"VBoxContainer/TabContainer/Free-for-all/FFAVBox/ClassicDeathmatch"
@onready var timed_combat_btn = $"VBoxContainer/TabContainer/Free-for-all/FFAVBox/TimedCombat"
@onready var last_plane_standing_btn = $"VBoxContainer/TabContainer/Free-for-all/FFAVBox/LastPlaneStanding"
@onready var quick_match_btn = $"VBoxContainer/TabContainer/Free-for-all/FFAVBox/QuickMatch"

# UI References - Team based Tab
@onready var team_deathmatch_btn = $VBoxContainer/TabContainer/TeamBased/TeamVBox/TeamDeathmatch
@onready var capture_flag_btn = $VBoxContainer/TabContainer/TeamBased/TeamVBox/CaptureTheFlag
@onready var domination_btn = $VBoxContainer/TabContainer/TeamBased/TeamVBox/Domination
@onready var squadron_btn = $VBoxContainer/TabContainer/TeamBased/TeamVBox/Squadron

# UI References - Common
@onready var tab_container = $VBoxContainer/TabContainer
@onready var start_server_button = $VBoxContainer/ButtonContainer/StartServerButton
@onready var back_button = $VBoxContainer/ButtonContainer/BackButton

# Configuration values
var player_lives: int = 3
var max_players: int = 4
var speed_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var has_time_limit: bool = false
var time_limit_minutes: int = 5
var hearts_enabled: bool = false
var clouds_enabled: bool = true
var selected_game_mode: String = ""
var game_mode_type: String = ""  # "ffa", "team", or "custom"

# Signals
signal server_config_confirmed(config: Dictionary)
signal back_to_main_menu

# Preset game modes
var ffa_presets = {
	"Classic Deathmatch": {
		"player_lives": 3,
		"max_players": 6,
		"speed_multiplier": 1.0,
		"damage_multiplier": 1.0,
		"has_time_limit": false,
		"hearts_enabled": false,
		"clouds_enabled": true
	},
	"Timed Combat": {
		"player_lives": 5,
		"max_players": 4,
		"speed_multiplier": 1.2,
		"damage_multiplier": 1.0,
		"has_time_limit": true,
		"time_limit_minutes": 10,
		"hearts_enabled": true,
		"clouds_enabled": true
	},
	"Last Plane Standing": {
		"player_lives": 1,
		"max_players": 8,
		"speed_multiplier": 0.8,
		"damage_multiplier": 1.5,
		"has_time_limit": false,
		"hearts_enabled": false,
		"clouds_enabled": false
	},
	"Quick Match": {
		"player_lives": 2,
		"max_players": 4,
		"speed_multiplier": 1.5,
		"damage_multiplier": 1.2,
		"has_time_limit": true,
		"time_limit_minutes": 5,
		"hearts_enabled": true,
		"clouds_enabled": true
	}
}

var team_presets = {
	"Team Deathmatch": {
		"player_lives": 3,
		"max_players": 6,
		"speed_multiplier": 1.0,
		"damage_multiplier": 1.0,
		"has_time_limit": true,
		"time_limit_minutes": 15,
		"hearts_enabled": true,
		"clouds_enabled": true
	},
	"Capture The Flag": {
		"player_lives": 5,
		"max_players": 8,
		"speed_multiplier": 1.2,
		"damage_multiplier": 0.8,
		"has_time_limit": true,
		"time_limit_minutes": 20,
		"hearts_enabled": true,
		"clouds_enabled": true
	},
	"Domination": {
		"player_lives": 4,
		"max_players": 6,
		"speed_multiplier": 1.0,
		"damage_multiplier": 1.0,
		"has_time_limit": true,
		"time_limit_minutes": 12,
		"hearts_enabled": true,
		"clouds_enabled": true
	},
	"Squadron vs Squadron": {
		"player_lives": 2,
		"max_players": 8,
		"speed_multiplier": 0.9,
		"damage_multiplier": 1.3,
		"has_time_limit": true,
		"time_limit_minutes": 18,
		"hearts_enabled": false,
		"clouds_enabled": false
	}
}

func _ready():
	# Set default values
	lives_spinbox.value = player_lives
	max_players_spinbox.value = max_players
	speed_slider.value = speed_multiplier
	damage_slider.value = damage_multiplier
	time_limit_checkbox.button_pressed = has_time_limit
	time_limit_spinbox.value = time_limit_minutes
	hearts_checkbox.button_pressed = hearts_enabled
	clouds_checkbox.button_pressed = clouds_enabled
	
	# Connect signals - Custom tab
	lives_spinbox.value_changed.connect(_on_lives_changed)
	max_players_spinbox.value_changed.connect(_on_max_players_changed)
	speed_slider.value_changed.connect(_on_speed_changed)
	damage_slider.value_changed.connect(_on_damage_changed)
	time_limit_checkbox.toggled.connect(_on_time_limit_toggled)
	time_limit_spinbox.value_changed.connect(_on_time_limit_value_changed)
	hearts_checkbox.toggled.connect(_on_hearts_toggled)
	clouds_checkbox.toggled.connect(_on_clouds_toggled)
	
	# Connect signals - FFA tab
	classic_deathmatch_btn.pressed.connect(_on_game_mode_selected.bind("Classic Deathmatch", "ffa"))
	timed_combat_btn.pressed.connect(_on_game_mode_selected.bind("Timed Combat", "ffa"))
	last_plane_standing_btn.pressed.connect(_on_game_mode_selected.bind("Last Plane Standing", "ffa"))
	quick_match_btn.pressed.connect(_on_game_mode_selected.bind("Quick Match", "ffa"))
	
	# Connect signals - Team tab
	team_deathmatch_btn.pressed.connect(_on_game_mode_selected.bind("Team Deathmatch", "team"))
	capture_flag_btn.pressed.connect(_on_game_mode_selected.bind("Capture The Flag", "team"))
	domination_btn.pressed.connect(_on_game_mode_selected.bind("Domination", "team"))
	squadron_btn.pressed.connect(_on_game_mode_selected.bind("Squadron vs Squadron", "team"))
	
	# Connect signals - Common
	start_server_button.pressed.connect(_on_start_server_pressed)
	back_button.pressed.connect(_on_back_pressed)
	tab_container.tab_changed.connect(_on_tab_changed)
	
	# Update labels
	_update_labels()
	_update_time_limit_visibility()

func _on_lives_changed(value: float):
	player_lives = int(value)
	_mark_as_custom()

func _on_max_players_changed(value: float):
	max_players = int(value)
	_mark_as_custom()

func _on_speed_changed(value: float):
	speed_multiplier = value
	_update_labels()
	_mark_as_custom()

func _on_damage_changed(value: float):
	damage_multiplier = value
	_update_labels()
	_mark_as_custom()

func _on_time_limit_toggled(pressed: bool):
	has_time_limit = pressed
	_update_time_limit_visibility()
	_mark_as_custom()

func _on_time_limit_value_changed(value: float):
	time_limit_minutes = int(value)
	_mark_as_custom()

func _on_hearts_toggled(pressed: bool):
	hearts_enabled = pressed
	_mark_as_custom()

func _on_clouds_toggled(pressed: bool):
	clouds_enabled = pressed
	_mark_as_custom()

func _on_game_mode_selected(mode_name: String, mode_type: String):
	selected_game_mode = mode_name
	game_mode_type = mode_type
	
	# Apply preset configuration
	var preset_config
	if mode_type == "ffa":
		preset_config = ffa_presets[mode_name]
	else:
		preset_config = team_presets[mode_name]
	
	_apply_preset_config(preset_config)
	print("Selected game mode: ", mode_name, " (", mode_type, ")")

func _on_tab_changed(tab: int):
	# Clear game mode selection when switching tabs
	if tab == 2:  # Custom tab
		_mark_as_custom()

func _apply_preset_config(config: Dictionary):
	player_lives = config.player_lives
	max_players = config.max_players
	speed_multiplier = config.speed_multiplier
	damage_multiplier = config.damage_multiplier
	has_time_limit = config.has_time_limit
	time_limit_minutes = config.get("time_limit_minutes", 5)
	hearts_enabled = config.hearts_enabled
	clouds_enabled = config.clouds_enabled
	
	# Update UI elements
	lives_spinbox.value = player_lives
	max_players_spinbox.value = max_players
	speed_slider.value = speed_multiplier
	damage_slider.value = damage_multiplier
	time_limit_checkbox.button_pressed = has_time_limit
	time_limit_spinbox.value = time_limit_minutes
	hearts_checkbox.button_pressed = hearts_enabled
	clouds_checkbox.button_pressed = clouds_enabled
	
	_update_labels()
	_update_time_limit_visibility()

func _mark_as_custom():
	selected_game_mode = ""
	game_mode_type = "custom"

func _update_labels():
	speed_value_label.text = "%.1fx" % speed_multiplier
	damage_value_label.text = "%.1fx" % damage_multiplier

func _update_time_limit_visibility():
	time_limit_spinbox.visible = has_time_limit

func _on_start_server_pressed():
	var config = {
		"player_lives": player_lives,
		"max_players": max_players,
		"speed_multiplier": speed_multiplier,
		"damage_multiplier": damage_multiplier,
		"has_time_limit": has_time_limit,
		"time_limit_minutes": time_limit_minutes,
		"hearts_enabled": hearts_enabled,
		"clouds_enabled": clouds_enabled,
		"game_mode": selected_game_mode,
		"game_mode_type": game_mode_type
	}
	server_config_confirmed.emit(config)

func _on_back_pressed():
	back_to_main_menu.emit() 
