extends Node2D

const SoftBody = preload("res://src/gdscript/SoftBody.gd")

var softbody = null

func _ready():
	softbody = SoftBody.create(7, 7, 450, 450, false, 10, 600, 30)
	# softbody.fixed[0] = true
	# softbody.fixed[9] = true

	for p in softbody.points:
		add_child(p)

func _physics_process(delta):
	if softbody:
		SoftBody.update(delta, softbody, 98)
		update()

func _draw():
	if softbody:
		SoftBody.draw(self, softbody, false)

func _input(event):
	if event is InputEventKey:
		if event.is_pressed():
			match event.scancode:
				KEY_W:
					for i in softbody.n_points:
						softbody.velocity[i] += Vector2(0, -60)
				KEY_S:
					for i in softbody.n_points:
						softbody.velocity[i] += Vector2(0, 60)
				KEY_A:
					for i in softbody.n_points:
						softbody.velocity[i] += Vector2(-60, 0)
				KEY_D:
					for i in softbody.n_points:
						softbody.velocity[i] += Vector2(60, 0)
