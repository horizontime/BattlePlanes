extends Control
class_name ServerConfig

# Game mode constants
const MODE_TEAM_ODDBALL = 5

# UI References - Custom Tab
@onready var lives_spinbox = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/LivesContainer/LivesSpinBox
@onready var max_players_spinbox = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/MaxPlayersContainer/MaxPlayersSpinBox
@onready var speed_slider = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/SpeedContainer/SpeedSlider
@onready var speed_value_label = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/SpeedContainer/SpeedValueLabel
@onready var damage_slider = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/DamageContainer/DamageSlider
@onready var damage_value_label = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/DamageContainer/DamageValueLabel
@onready var time_limit_checkbox = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/TimeLimitContainer/TimeLimitCheckBox
@onready var time_limit_spinbox = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/TimeLimitContainer/TimeLimitSpinBox

@onready var clouds_checkbox = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/CloudsContainer/CloudsCheckBox
@onready var team_mode_checkbox = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/TeamModeContainer/TeamModeCheckBox
@onready var slayer_button = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/SlayerContainer/SlayerButton
@onready var oddball_button = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/OddballContainer/OddballButton
@onready var koth_button = $VBoxContainer/TabContainer/Custom/ScrollContainer/MarginContainer/CustomVBox/KOTHContainer/KOTHButton

# UI References - Free-for-all Tab
@onready var classic_deathmatch_btn = $"VBoxContainer/TabContainer/Free-for-all/ScrollContainer/MarginContainer/FFAVBox/ClassicDeathmatch"
@onready var last_man_standing_btn = $"VBoxContainer/TabContainer/Free-for-all/ScrollContainer/MarginContainer/FFAVBox/LastManStanding"
@onready var oddball_btn = $"VBoxContainer/TabContainer/Free-for-all/ScrollContainer/MarginContainer/FFAVBox/Oddball"
@onready var koth_btn = $"VBoxContainer/TabContainer/Free-for-all/ScrollContainer/MarginContainer/FFAVBox/KingOfTheHill"

# UI References - Free-for-all Descriptions
@onready var classic_deathmatch_desc = $"VBoxContainer/TabContainer/Free-for-all/ScrollContainer/MarginContainer/FFAVBox/ClassicDeathmatchDesc"
@onready var last_man_standing_desc = $"VBoxContainer/TabContainer/Free-for-all/ScrollContainer/MarginContainer/FFAVBox/LastManStandingDesc"
@onready var oddball_desc = $"VBoxContainer/TabContainer/Free-for-all/ScrollContainer/MarginContainer/FFAVBox/OddballDesc"
@onready var koth_desc = $"VBoxContainer/TabContainer/Free-for-all/ScrollContainer/MarginContainer/FFAVBox/KingOfTheHillDesc"

# UI References - Team Modes Tab
@onready var team_slayer_btn = $"VBoxContainer/TabContainer/Team Modes/ScrollContainer/MarginContainer/TeamVBox/TeamSlayer"
@onready var team_oddball_btn = $"VBoxContainer/TabContainer/Team Modes/ScrollContainer/MarginContainer/TeamVBox/TeamOddball"
@onready var team_koth_btn = $"VBoxContainer/TabContainer/Team Modes/ScrollContainer/MarginContainer/TeamVBox/TeamKingOfTheHill"

# UI References - Team Modes Descriptions
@onready var team_slayer_desc = $"VBoxContainer/TabContainer/Team Modes/ScrollContainer/MarginContainer/TeamVBox/TeamSlayerDesc"
@onready var team_oddball_desc = $"VBoxContainer/TabContainer/Team Modes/ScrollContainer/MarginContainer/TeamVBox/TeamOddballDesc"
@onready var team_koth_desc = $"VBoxContainer/TabContainer/Team Modes/ScrollContainer/MarginContainer/TeamVBox/TeamKingOfTheHillDesc"

# UI References - Common
@onready var tab_container = $VBoxContainer/TabContainer
@onready var start_server_button = $VBoxContainer/ButtonContainer/StartServerButton
@onready var back_button = $VBoxContainer/ButtonContainer/BackButton

# Configuration values
var player_lives: int = 3
var max_players: int = 4
var speed_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var has_time_limit: bool = true
var time_limit_minutes: int = 5

var clouds_enabled: bool = true
var team_mode: bool = false
var slayer_mode: bool = true  # Default to slayer mode
var oddball_mode: bool = false
var koth_mode: bool = false
var selected_game_mode: String = ""
var game_mode_type: String = ""  # "ffa", "team", or "custom"

# Signals
signal server_config_confirmed(config: Dictionary)
signal back_to_main_menu

# Preset game modes
var ffa_presets = {
	"FFA Slayer": {
		"player_lives": -1,
		"max_players": 6,
		"speed_multiplier": 1.0,
		"damage_multiplier": 1.0,
		"has_time_limit": true,
		"time_limit_minutes": 5,
		"kill_limit": 15,

		"clouds_enabled": true
	},
	"Last Man Standing": {
		"player_lives": 7,
		"max_players": 8,
		"speed_multiplier": 1.0,
		"damage_multiplier": 1.0,
		"has_time_limit": true,
		"time_limit_minutes": 5,

		"clouds_enabled": true
	},
	"Oddball": {
		"player_lives": 3,
		"max_players": 6,
		"speed_multiplier": 1.0,
		"damage_multiplier": 1.0,
		"has_time_limit": true,
		"time_limit_minutes": 5,

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

		"clouds_enabled": true,
		"koth_mode": true
	}
}

var team_presets = {
	"Team Slayer": {
		"player_lives": -1,
		"max_players": 6,
		"speed_multiplier": 1.0,
		"damage_multiplier": 1.0,
		"has_time_limit": true,
		"time_limit_minutes": 5,

		"clouds_enabled": true
	},

	"Team Oddball": {
		"is_team_mode": true,
		"player_lives": -1,  # Unlimited lives
		"max_players": 6,
		"speed_multiplier": 1.0,
		"damage_multiplier": 1.0,
		"has_time_limit": true,
		"time_limit_minutes": 5,
		"score_limit": 100,
		"friendly_fire": true,
		"unlimited_lives": true,
		"skull_enabled": true,

		"clouds_enabled": true,
		"oddball_mode": true
	},
	"Team King of the Hill": {
		"is_team_mode": true,
		"player_lives": -1,  # Unlimited lives
		"max_players": 6,
		"speed_multiplier": 1.0,
		"damage_multiplier": 1.0,
		"has_time_limit": true,
		"time_limit_minutes": 5,
		"score_limit": 100,
		"friendly_fire": true,
		"unlimited_lives": true,
		"hill_enabled": true,

		"clouds_enabled": true,
		"koth_mode": true
	}
}

# Game mode descriptions
var ffa_descriptions = {
	"FFA Slayer": "Fast-paced elimination combat\n• Unlimited lives\n• Up to 6 players\n• 5 minute time limit\n• First to 15 kills wins",
	"Last Man Standing": "Survival-based elimination mode\n• 7 Lives per player\n• Up to 8 players\n• 5 minute time limit\n• Last player alive wins",
	"Oddball": "Hold the skull to score points\n• Unlimited lives\n• Up to 6 players\n• 5 minute time limit\n• First to 60 seconds wins\n• Skull dropped when killed",
	"King of the Hill": "Control the hill to score points\n• Unlimited lives\n• Up to 6 players\n• 5 minute time limit\n• First to 60 seconds wins\n• Hill moves every 30 seconds"
}

var team_descriptions = {
	"Team Slayer": "Team vs team combat\n• Unlimited lives\n• Up to 6 players\n• 5 minute time limit\n• First team to 30 kills wins\n• Friendly-fire penalty active",

	"Team Oddball": "Hold the skull as a team for 100 s to win.\n• Unlimited lives\n• Up to 6 players\n• 100 second time limit\n• First team to hold skull for total of 100s wins\n• Friendly-fire penalty active",
	"Team King of the Hill": "Control the hill as a team for 100 s to win.\n• Up to 6 players\n• 5 minute time limit\n• First team to hold hill for total of 100s wins\n• Hill moves every 30 seconds"
}

func _ready():
	# Set default values
	lives_spinbox.value = player_lives
	max_players_spinbox.value = max_players
	speed_slider.value = speed_multiplier
	damage_slider.value = damage_multiplier
	time_limit_checkbox.button_pressed = has_time_limit
	time_limit_spinbox.value = time_limit_minutes

	clouds_checkbox.button_pressed = clouds_enabled
	team_mode_checkbox.button_pressed = team_mode
	slayer_button.button_pressed = slayer_mode
	oddball_button.button_pressed = oddball_mode
	koth_button.button_pressed = koth_mode
	
	# Configure game mode buttons for single-click interaction
	_configure_game_mode_buttons()
	
	# Connect signals - Custom tab
	lives_spinbox.value_changed.connect(_on_lives_changed)
	max_players_spinbox.value_changed.connect(_on_max_players_changed)
	speed_slider.value_changed.connect(_on_speed_changed)
	damage_slider.value_changed.connect(_on_damage_changed)
	time_limit_checkbox.toggled.connect(_on_time_limit_toggled)
	time_limit_spinbox.value_changed.connect(_on_time_limit_value_changed)

	clouds_checkbox.toggled.connect(_on_clouds_toggled)
	team_mode_checkbox.toggled.connect(_on_team_mode_toggled)
	slayer_button.toggled.connect(_on_game_mode_radio_toggled.bind("slayer"))
	oddball_button.toggled.connect(_on_game_mode_radio_toggled.bind("oddball"))
	koth_button.toggled.connect(_on_game_mode_radio_toggled.bind("koth"))
	
	# Connect signals - FFA tab
	classic_deathmatch_btn.pressed.connect(_on_game_mode_selected.bind("FFA Slayer", "ffa"))
	last_man_standing_btn.pressed.connect(_on_game_mode_selected.bind("Last Man Standing", "ffa"))
	oddball_btn.pressed.connect(_on_game_mode_selected.bind("Oddball", "ffa"))
	koth_btn.pressed.connect(_on_game_mode_selected.bind("King of the Hill", "ffa"))
	
	# Connect signals - Team tab
	team_slayer_btn.pressed.connect(_on_game_mode_selected.bind("Team Slayer", "team"))

	team_oddball_btn.pressed.connect(_on_game_mode_selected.bind("Team Oddball", "team"))
	team_koth_btn.pressed.connect(_on_game_mode_selected.bind("Team King of the Hill", "team"))
	
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


	_mark_as_custom()

func _on_clouds_toggled(pressed: bool):
	clouds_enabled = pressed
	_mark_as_custom()

func _on_team_mode_toggled(pressed: bool):
	team_mode = pressed
	_mark_as_custom()

func _on_game_mode_radio_toggled(mode: String, pressed: bool):
	if pressed:
		# Set the selected game mode (ButtonGroup handles mutual exclusivity)
		slayer_mode = (mode == "slayer")
		oddball_mode = (mode == "oddball")
		koth_mode = (mode == "koth")
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
	last_man_standing_desc.visible = false
	oddball_desc.visible = false
	koth_desc.visible = false
	
	# Hide Team descriptions
	team_slayer_desc.visible = false
	team_oddball_desc.visible = false
	team_koth_desc.visible = false

func _show_description(mode_name: String, mode_type: String):
	var description_text = ""
	var description_container = null
	
	# Get description text and container
	if mode_type == "ffa":
		description_text = ffa_descriptions[mode_name]
		match mode_name:
			"FFA Slayer":
				description_container = classic_deathmatch_desc
			"Last Man Standing":
				description_container = last_man_standing_desc
			"Oddball":
				description_container = oddball_desc
			"King of the Hill":
				description_container = koth_desc
	else:  # team mode
		description_text = team_descriptions[mode_name]
		match mode_name:
			"Team Slayer":
				description_container = team_slayer_desc

			"Team Oddball":
				description_container = team_oddball_desc
			"Team King of the Hill":
				description_container = team_koth_desc
	
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

	clouds_enabled = config.clouds_enabled
	team_mode = config.get("is_team_mode", false)
	slayer_mode = config.get("slayer_mode", true)
	oddball_mode = config.get("oddball_mode", false)
	koth_mode = config.get("koth_mode", false)
	
	# Update UI elements
	lives_spinbox.value = player_lives
	max_players_spinbox.value = max_players
	speed_slider.value = speed_multiplier
	damage_slider.value = damage_multiplier
	time_limit_checkbox.button_pressed = has_time_limit
	time_limit_spinbox.value = time_limit_minutes

	clouds_checkbox.button_pressed = clouds_enabled
	team_mode_checkbox.button_pressed = team_mode
	slayer_button.button_pressed = slayer_mode
	oddball_button.button_pressed = oddball_mode
	koth_button.button_pressed = koth_mode
	
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
	# Determine the correct game_mode and game_mode_type based on current tab and selections
	var final_game_mode = selected_game_mode
	var final_game_mode_type = game_mode_type
	
	var current_tab = tab_container.current_tab
	
	if current_tab == 2:  # Custom tab
		# Read the selected radio button id/name and Team Mode checkbox state
		var selected_radio_mode = ""
		if slayer_button.button_pressed:
			selected_radio_mode = "slayer"
		elif oddball_button.button_pressed:
			selected_radio_mode = "oddball"
		elif koth_button.button_pressed:
			selected_radio_mode = "koth"
		
		# Read Team Mode checkbox state
		var is_team_mode = team_mode_checkbox.button_pressed
		
		# Map custom tab selections to proper game modes - the radio buttons (slayer/oddball/koth)
		# combined with Team Mode checkbox determine FFA vs Team variant for each game type
		if selected_radio_mode != "":
			if selected_radio_mode == "slayer":
				if is_team_mode:
					final_game_mode = "Team Slayer"
					final_game_mode_type = "team"
				else:
					final_game_mode = "FFA Slayer"
					final_game_mode_type = "ffa"
				# Update mode flags based on radio selection
				slayer_mode = true
				oddball_mode = false
				koth_mode = false
			elif selected_radio_mode == "oddball":
				if is_team_mode:
					final_game_mode = "Team Oddball"
					final_game_mode_type = "team"
				else:
					final_game_mode = "Oddball"
					final_game_mode_type = "ffa"
				# Update mode flags based on radio selection
				slayer_mode = false
				oddball_mode = true
				koth_mode = false
			elif selected_radio_mode == "koth":
				if is_team_mode:
					final_game_mode = "Team King of the Hill"
					final_game_mode_type = "team"
				else:
					final_game_mode = "King of the Hill"
					final_game_mode_type = "ffa"
				# Update mode flags based on radio selection
				slayer_mode = false
				oddball_mode = false
				koth_mode = true
		else:
			# Keep "custom" as fallback only if no radio is selected in Custom tab
			final_game_mode_type = "custom"
	
	# For standard tabs (FFA and Team), the selected_game_mode and game_mode_type are already correct
	# from the _on_game_mode_selected() calls, so we use them as-is
	
	var config = {
		"player_lives": player_lives,
		"max_players": max_players,
		"speed_multiplier": speed_multiplier,
		"damage_multiplier": damage_multiplier,
		"has_time_limit": has_time_limit,
		"time_limit_minutes": time_limit_minutes,

		"clouds_enabled": clouds_enabled,
		"team_mode": team_mode,
		"slayer_mode": slayer_mode,
		"oddball_mode": oddball_mode,
		"koth_mode": koth_mode,
		"game_mode": final_game_mode,
		"game_mode_type": final_game_mode_type
	}
	server_config_confirmed.emit(config)

func _on_back_pressed():
	back_to_main_menu.emit() 

func _configure_game_mode_buttons():
	# Configure FFA buttons
	classic_deathmatch_btn.focus_mode = Control.FOCUS_ALL
	classic_deathmatch_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Configure Team buttons
	team_slayer_btn.focus_mode = Control.FOCUS_ALL
	team_slayer_btn.mouse_filter = Control.MOUSE_FILTER_STOP

	team_oddball_btn.focus_mode = Control.FOCUS_ALL
	team_oddball_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	team_koth_btn.focus_mode = Control.FOCUS_ALL
	team_koth_btn.mouse_filter = Control.MOUSE_FILTER_STOP
