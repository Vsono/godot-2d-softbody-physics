extends SoftBody2D
var softbody = null

func _ready():
	create(10, 10, 450, 450, true)
	fixed[0] = true
	fixed[9] = true

	auto_draw = true