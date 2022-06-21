extends Node2D

const SoftBody = preload("res://src/gdscript/SoftBody.gd")

var softbody = null

func _ready():
	softbody = SoftBody.create(10, 10, 450, 450, true, 10, 600, 30)
	softbody.fixed[0] = true
	softbody.fixed[9] = true

	for p in softbody.points:
		add_child(p)

func _physics_process(delta):
	if softbody:
		SoftBody.update(delta, softbody)
		update()

func _draw():
	if softbody:
		SoftBody.draw(self, softbody, false)
