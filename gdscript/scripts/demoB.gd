extends Node2D

const SoftBody = preload("SoftBody.gd")

var softbody = null

func _ready():
	softbody = SoftBody.create(10, 10, 300, 300)
	softbody.fixed[0] = true
	softbody.fixed[9] = true

func _physics_process(delta):
	if softbody:
		SoftBody.update(delta * 10, softbody)
		update()

func _draw():
	if softbody:
		SoftBody.draw(self, softbody, false)
