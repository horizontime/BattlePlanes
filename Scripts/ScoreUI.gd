extends Panel

var game_manager
@onready var player_scores_text = $PlayerScores

func _ready():
	game_manager = get_tree().get_current_scene().get_node("GameManager")

func _process(delta):
	player_scores_text.text = ""
	
	for player in game_manager.players:
		var text = str(player.player_name, " - ", player.score, "\n")
		player_scores_text.text += text
