extends Control
class_name ServerConfig

# UI References
@onready var lives_spinbox = $VBoxContainer/LivesContainer/LivesSpinBox
@onready var max_players_spinbox = $VBoxContainer/MaxPlayersContainer/MaxPlayersSpinBox
@onready var speed_slider = $VBoxContainer/SpeedContainer/SpeedSlider
@onready var speed_value_label = $VBoxContainer/SpeedContainer/SpeedValueLabel
@onready var damage_slider = $VBoxContainer/DamageContainer/DamageSlider
@onready var damage_value_label = $VBoxContainer/DamageContainer/DamageValueLabel
@onready var time_limit_checkbox = $VBoxContainer/TimeLimitContainer/TimeLimitCheckBox
@onready var time_limit_spinbox = $VBoxContainer/TimeLimitContainer/TimeLimitSpinBox
@onready var start_server_button = $VBoxContainer/ButtonContainer/StartServerButton
@onready var back_button = $VBoxContainer/ButtonContainer/BackButton

# Configuration values
var player_lives: int = 3
var max_players: int = 4
var speed_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var has_time_limit: bool = false
var time_limit_minutes: int = 5

# Signals
signal server_config_confirmed(config: Dictionary)
signal back_to_main_menu

func _ready():
	# Set default values
	lives_spinbox.value = player_lives
	max_players_spinbox.value = max_players
	speed_slider.value = speed_multiplier
	damage_slider.value = damage_multiplier
	time_limit_checkbox.button_pressed = has_time_limit
	time_limit_spinbox.value = time_limit_minutes
	
	# Connect signals
	lives_spinbox.value_changed.connect(_on_lives_changed)
	max_players_spinbox.value_changed.connect(_on_max_players_changed)
	speed_slider.value_changed.connect(_on_speed_changed)
	damage_slider.value_changed.connect(_on_damage_changed)
	time_limit_checkbox.toggled.connect(_on_time_limit_toggled)
	time_limit_spinbox.value_changed.connect(_on_time_limit_value_changed)
	start_server_button.pressed.connect(_on_start_server_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Update labels
	_update_labels()
	_update_time_limit_visibility()

func _on_lives_changed(value: float):
	player_lives = int(value)

func _on_max_players_changed(value: float):
	max_players = int(value)

func _on_speed_changed(value: float):
	speed_multiplier = value
	_update_labels()

func _on_damage_changed(value: float):
	damage_multiplier = value
	_update_labels()

func _on_time_limit_toggled(pressed: bool):
	has_time_limit = pressed
	_update_time_limit_visibility()

func _on_time_limit_value_changed(value: float):
	time_limit_minutes = int(value)

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
		"time_limit_minutes": time_limit_minutes
	}
	server_config_confirmed.emit(config)

func _on_back_pressed():
	back_to_main_menu.emit() 