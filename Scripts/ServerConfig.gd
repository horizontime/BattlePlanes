extends Control
class_name ServerConfig

# UI References - Custom Tab
@onready var lives_spinbox = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/LivesContainer/LivesSpinBox
@onready var max_players_spinbox = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/MaxPlayersContainer/MaxPlayersSpinBox
@onready var speed_slider = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/SpeedContainer/SpeedSlider
@onready var speed_value_label = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/SpeedContainer/SpeedValueLabel
@onready var damage_slider = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/DamageContainer/DamageSlider
@onready var damage_value_label = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/DamageContainer/DamageValueLabel
@onready var time_limit_checkbox = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/TimeLimitContainer/TimeLimitCheckBox
@onready var time_limit_spinbox = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/TimeLimitContainer/TimeLimitSpinBox
@onready var hearts_checkbox = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/HeartsContainer/HeartsCheckBox
@onready var clouds_checkbox = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/CloudsContainer/CloudsCheckBox
@onready var oddball_checkbox = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/OddballContainer/OddballCheckBox
@onready var koth_checkbox = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/KOTHContainer/KOTHCheckBox

# UI References - Free-for-all Tab
@onready var classic_deathmatch_btn = $"VBoxContainer/TabContainer/Free-for-all/ScrollContainer/MarginContainer/FFAVBox/ClassicDeathmatch"
@onready var oddball_btn = $"VBoxContainer/TabContainer/Free-for-all/ScrollContainer/MarginContainer/FFAVBox/Oddball"
@onready var koth_btn = $"VBoxContainer/TabContainer/Free-for-all/ScrollContainer/MarginContainer/FFAVBox/KingOfTheHill"

# UI References - Free-for-all Descriptions
@onready var classic_deathmatch_desc = $"VBoxContainer/TabContainer/Free-for-all/ScrollContainer/MarginContainer/FFAVBox/ClassicDeathmatchDesc"
@onready var oddball_desc = $"VBoxContainer/TabContainer/Free-for-all/ScrollContainer/MarginContainer/FFAVBox/OddballDesc"
@onready var koth_desc = $"VBoxContainer/TabContainer/Free-for-all/ScrollContainer/MarginContainer/FFAVBox/KingOfTheHillDesc"

# UI References - Team Modes Tab
@onready var team_deathmatch_btn = $"VBoxContainer/TabContainer/Team Modes/ScrollContainer/MarginContainer/TeamVBox/TeamDeathmatch"
@onready var capture_flag_btn = $"VBoxContainer/TabContainer/Team Modes/ScrollContainer/MarginContainer/TeamVBox/CaptureTheFlag"

# UI References - Team Modes Descriptions
@onready var team_deathmatch_desc = $"VBoxContainer/TabContainer/Team Modes/ScrollContainer/MarginContainer/TeamVBox/TeamDeathmatchDesc"
@onready var capture_flag_desc = $"VBoxContainer/TabContainer/Team Modes/ScrollContainer/MarginContainer/TeamVBox/CaptureTheFlagDesc"

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
var oddball_mode: bool = false
var koth_mode: bool = false
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

	"Oddball": {
		"player_lives": 3,
		"max_players": 6,
		"speed_multiplier": 1.0,
		"damage_multiplier": 1.0,
		"has_time_limit": true,
		"time_limit_minutes": 5,
		"hearts_enabled": false,
		"clouds_enabled": true,
		"oddball_mode": true
	},
	"King of the Hill": {
		"player_lives": -1,  # Unlimited lives
		"max_players": 6,
		"speed_multiplier": 1.0,
		"damage_multiplier": 1.0,
		"has_time_limit": true,
		"time_limit_minutes": 5,
		"hearts_enabled": false,
		"clouds_enabled": true,
		"koth_mode": true
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

}

# Game mode descriptions
var ffa_descriptions = {
	"Classic Deathmatch": "Standard dogfight action\n• 3 Lives per player\n• Up to 6 players\n• No time limit\n• Classic combat experience",
	"Oddball": "Hold the skull to score points\n• Unlimited lives\n• Up to 6 players\n• 5 minute time limit\n• First to 60 seconds wins\n• Drop skull when killed",
	"King of the Hill": "Control the hill to score points\n• Unlimited lives\n• Up to 6 players\n• 5 minute time limit\n• First to 60 seconds wins\n• Hill moves every 30 seconds"
}

var team_descriptions = {
	"Team Deathmatch": "Team vs team combat\n• 3 Lives per player\n• Up to 6 players\n• 15 minute time limit\n• Heart powerups enabled\n• Balanced team warfare",
	"Capture The Flag": "Capture and defend objectives\n• 5 Lives per player\n• Up to 8 players\n• 20 minute time limit\n• 1.2x speed, 0.8x damage\n• Extended tactical gameplay"
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
	oddball_checkbox.button_pressed = oddball_mode
	koth_checkbox.button_pressed = koth_mode
	
	# Configure game mode buttons for single-click interaction
	_configure_game_mode_buttons()
	
	# Connect signals - Custom tab
	lives_spinbox.value_changed.connect(_on_lives_changed)
	max_players_spinbox.value_changed.connect(_on_max_players_changed)
	speed_slider.value_changed.connect(_on_speed_changed)
	damage_slider.value_changed.connect(_on_damage_changed)
	time_limit_checkbox.toggled.connect(_on_time_limit_toggled)
	time_limit_spinbox.value_changed.connect(_on_time_limit_value_changed)
	hearts_checkbox.toggled.connect(_on_hearts_toggled)
	clouds_checkbox.toggled.connect(_on_clouds_toggled)
	oddball_checkbox.toggled.connect(_on_oddball_toggled)
	koth_checkbox.toggled.connect(_on_koth_toggled)
	
	# Connect signals - FFA tab
	classic_deathmatch_btn.pressed.connect(_on_game_mode_selected.bind("Classic Deathmatch", "ffa"))
	oddball_btn.pressed.connect(_on_game_mode_selected.bind("Oddball", "ffa"))
	koth_btn.pressed.connect(_on_game_mode_selected.bind("King of the Hill", "ffa"))
	
	# Connect signals - Team tab
	team_deathmatch_btn.pressed.connect(_on_game_mode_selected.bind("Team Deathmatch", "team"))
	capture_flag_btn.pressed.connect(_on_game_mode_selected.bind("Capture The Flag", "team"))
	
	# Connect signals - Common
	start_server_button.pressed.connect(_on_start_server_pressed)
	back_button.pressed.connect(_on_back_pressed)
	tab_container.tab_changed.connect(_on_tab_changed)
	
	# Update labels
	_update_labels()
	_update_time_limit_visibility()
	_update_start_button_state()

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

func _on_oddball_toggled(pressed: bool):
	oddball_mode = pressed
	_mark_as_custom()

func _on_koth_toggled(pressed: bool):
	koth_mode = pressed
	_mark_as_custom()

func _on_game_mode_selected(mode_name: String, mode_type: String):
	selected_game_mode = mode_name
	game_mode_type = mode_type
	
	# Hide all descriptions first
	_hide_all_descriptions()
	
	# Show the selected description
	_show_description(mode_name, mode_type)
	
	# Apply preset configuration
	var preset_config
	if mode_type == "ffa":
		preset_config = ffa_presets[mode_name]
	else:
		preset_config = team_presets[mode_name]
	
	_apply_preset_config(preset_config)
	_update_start_button_state()
	print("Selected game mode: ", mode_name, " (", mode_type, ")")

func _hide_all_descriptions():
	# Hide FFA descriptions
	classic_deathmatch_desc.visible = false
	oddball_desc.visible = false
	koth_desc.visible = false
	
	# Hide Team descriptions
	team_deathmatch_desc.visible = false
	capture_flag_desc.visible = false

func _show_description(mode_name: String, mode_type: String):
	var description_text = ""
	var description_container = null
	
	# Get description text and container
	if mode_type == "ffa":
		description_text = ffa_descriptions[mode_name]
		match mode_name:
			"Classic Deathmatch":
				description_container = classic_deathmatch_desc
			"Oddball":
				description_container = oddball_desc
			"King of the Hill":
				description_container = koth_desc
	else:  # team mode
		description_text = team_descriptions[mode_name]
		match mode_name:
			"Team Deathmatch":
				description_container = team_deathmatch_desc
			"Capture The Flag":
				description_container = capture_flag_desc
	
	# Show description
	if description_container:
		var desc_label = description_container.get_node("DescPanel/DescMargin/DescLabel")
		if desc_label:
			desc_label.text = description_text
			description_container.visible = true

func _on_tab_changed(tab: int):
	# Hide all descriptions when switching tabs
	_hide_all_descriptions()
	
	# Clear game mode selection when switching tabs
	if tab == 2:  # Custom tab
		_mark_as_custom()
	else:
		# For FFA (tab 0) or Team (tab 1) tabs, clear the selection
		selected_game_mode = ""
		if tab == 0:
			game_mode_type = "ffa"
		elif tab == 1:
			game_mode_type = "team"
	_update_start_button_state()

func _apply_preset_config(config: Dictionary):
	player_lives = config.player_lives
	max_players = config.max_players
	speed_multiplier = config.speed_multiplier
	damage_multiplier = config.damage_multiplier
	has_time_limit = config.has_time_limit
	time_limit_minutes = config.get("time_limit_minutes", 5)
	hearts_enabled = config.hearts_enabled
	clouds_enabled = config.clouds_enabled
	oddball_mode = config.get("oddball_mode", false)
	koth_mode = config.get("koth_mode", false)
	
	# Update UI elements
	lives_spinbox.value = player_lives
	max_players_spinbox.value = max_players
	speed_slider.value = speed_multiplier
	damage_slider.value = damage_multiplier
	time_limit_checkbox.button_pressed = has_time_limit
	time_limit_spinbox.value = time_limit_minutes
	hearts_checkbox.button_pressed = hearts_enabled
	clouds_checkbox.button_pressed = clouds_enabled
	oddball_checkbox.button_pressed = oddball_mode
	koth_checkbox.button_pressed = koth_mode
	
	_update_labels()
	_update_time_limit_visibility()
	_update_start_button_state()

func _mark_as_custom():
	selected_game_mode = ""
	game_mode_type = "custom"

func _update_labels():
	speed_value_label.text = "%.1fx" % speed_multiplier
	damage_value_label.text = "%.1fx" % damage_multiplier

func _update_time_limit_visibility():
	time_limit_spinbox.visible = has_time_limit

func _update_start_button_state():
	var current_tab = tab_container.current_tab
	var is_valid_config = false
	
	if current_tab == 2:  # Custom tab
		is_valid_config = true
	elif current_tab == 0:  # Free-for-all tab
		if selected_game_mode != "" and selected_game_mode in ffa_presets:
			is_valid_config = true
	elif current_tab == 1:  # Team Modes tab
		if selected_game_mode != "" and selected_game_mode in team_presets:
			is_valid_config = true
	
	start_server_button.disabled = !is_valid_config
	
	# Prevent the button from being focusable when disabled to avoid white outline
	if is_valid_config:
		start_server_button.focus_mode = Control.FOCUS_ALL
	else:
		start_server_button.focus_mode = Control.FOCUS_NONE

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
		"oddball_mode": oddball_mode,
		"koth_mode": koth_mode,
		"game_mode": selected_game_mode,
		"game_mode_type": game_mode_type
	}
	server_config_confirmed.emit(config)

func _on_back_pressed():
	back_to_main_menu.emit() 

func _configure_game_mode_buttons():
	# Configure FFA buttons
	classic_deathmatch_btn.focus_mode = Control.FOCUS_ALL
	classic_deathmatch_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Configure Team buttons
	team_deathmatch_btn.focus_mode = Control.FOCUS_ALL
	team_deathmatch_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	capture_flag_btn.focus_mode = Control.FOCUS_ALL
	capture_flag_btn.mouse_filter = Control.MOUSE_FILTER_STOP 
