extends Node2D

var hill_radius: float = 80.0

func _draw():
	"""Draw the hill visual - light blue circle with dark blue border"""
	# Fill circle (light blue with 50% transparency)
	draw_circle(Vector2.ZERO, hill_radius, Color(0.5, 0.8, 1.0, 0.5))
	
	# Border circle (dark blue)
	draw_arc(Vector2.ZERO, hill_radius, 0, TAU, 64, Color(0.2, 0.4, 0.8, 1.0), 3.0)
