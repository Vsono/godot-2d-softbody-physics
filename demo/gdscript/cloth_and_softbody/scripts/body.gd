extends SoftBody2D

func _ready():
	create(7, 7, 450, 450)

	stiffness = 600
	auto_draw = true

func _input(event):
	if event is InputEventKey:
		if event.is_pressed():
			var n_points = len(points)
			match event.scancode:
				KEY_W:
					for i in n_points:
						velocities[i] += Vector2(0, -60)
				KEY_S:
					for i in n_points:
						velocities[i] += Vector2(0, 60)
				KEY_A:
					for i in n_points:
						velocities[i] += Vector2(-60, 0)
				KEY_D:
					for i in n_points:
						velocities[i] += Vector2(60, 0)
