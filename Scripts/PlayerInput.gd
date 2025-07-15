extends MultiplayerSynchronizer

@export var throttle_input : float
@export var turn_input : float
@export var shoot_input : bool

func _ready():
	# disable the _physics_process function for all
	# who does not control this player
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_physics_process(false)

func _physics_process(delta):
	throttle_input = Input.get_axis("throttle_down", "throttle_up")
	turn_input = Input.get_axis("turn_left", "turn_right")
	shoot_input = Input.is_action_pressed("shoot")
