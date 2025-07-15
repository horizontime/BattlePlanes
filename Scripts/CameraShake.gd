extends Camera2D

var intensity : float = 3.0
var max_duration : float
var cur_duration : float

func _process(delta):
	if cur_duration <= 0:
		return
	
	cur_duration = move_toward(cur_duration, 0.0, delta)
	var dur_prc = cur_duration / max_duration
	
	var x = randf_range(-dur_prc, dur_prc)
	var y = randf_range(-dur_prc, dur_prc)
	var pos = Vector2(x, y) * intensity
	
	offset = pos

# called when the player is hit/destroyed
func shake (shake_duration : float, shake_intensity : float):
	intensity = shake_intensity
	cur_duration = shake_duration
	max_duration = shake_duration
