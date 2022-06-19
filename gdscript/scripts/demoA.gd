extends Node2D

const SoftBody = preload("SoftBody.gd")

var softbody = null

func _ready():
	softbody = SoftBody.create_softbody(20, 20, 300, 300, true, 10, 5)
	softbody.fixed[0] = true
	softbody.fixed[19] = true

func _physics_process(delta):
	if softbody:
		SoftBody.update_softbody(delta * 10, softbody)
		update()

func _draw():
	if softbody:
		draw_softbody(softbody, false)


func draw_softbody(body, draw_points: bool=true, draw_connections: bool=true):
	if draw_points:
		for position in body.position:
			draw_circle(position, 1, Color.white)
	
	if draw_connections:
		for spring in body.spring:
			draw_line(body.position[spring[0]], body.position[spring[1]], Color.white)
