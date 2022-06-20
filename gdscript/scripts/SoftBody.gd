
# position = [Vector2, ...]
# velocity = [Vector2, ...]
# fixed = [bool, ...]
# spring = [[index, index, length], ...]
static func create(rows: int, columns: int, width: float, height: float, cloth: bool=false, mass: float=10, stiffness: float = 1, damping_factor: float = 1) -> Dictionary:
	var points = []
	var position = []
	var velocity = []
	var fixed = []
	var spring = []

	var dx = width / rows
	var dy = height / columns
	var dd = sqrt(dx * dx + dy * dy)

	for ci in range(columns):
		for ri in range(rows):
			var point = RigidBody2D.new()
			var col_shape = CollisionShape2D.new()
			col_shape.shape = CircleShape2D.new()
			col_shape.shape.radius = 3
			point.add_child(col_shape)
			points.append(point)

			point.position = Vector2(ri * dx, ci * dy)
			point.mass = 0.1
			point.gravity_scale = 0.1
			
			position.append(Vector2(ri * dx, ci * dy))
			velocity.append(Vector2(0, 0))
			fixed.append(false)

			if ri < rows - 1:
				spring.append([ci * rows + ri, ci * rows + ri + 1, dx])
			if ci < columns - 1:
				spring.append([ci * rows + ri, ci * rows + ri + rows, dy])
				if cloth:
					continue

				if ri < rows - 1:
					spring.append([ci * rows + ri, ci * rows + ri + rows + 1, dd])
				if ri > 0:
					spring.append([ci * rows + ri, ci * rows + ri + rows - 1, dd])
	
	return {
		'stiffness': stiffness, 'damping_factor': damping_factor,
		'n_points': rows * columns, 'mass': float(mass),
		'position': position, 'velocity': velocity,
		'fixed': fixed, 'spring': spring, 'points': points
	}


static func update(delta, body, gravity=9.8):
	for spring in body.spring:
		var force = Vector2(0, 0)

		var relative_position = body.points[spring[1]].position - body.points[spring[0]].position
		var direction = relative_position.normalized()

		force += direction.dot(body.points[spring[1]].linear_velocity - body.points[spring[0]].linear_velocity) * direction * body.damping_factor

		force += (relative_position - relative_position.normalized() * spring[2]) * body.stiffness

		if not body.fixed[spring[0]]:
			body.points[spring[0]].linear_velocity += force * delta
		if not body.fixed[spring[1]]:
			body.points[spring[1]].linear_velocity -= force * delta
	
	var point_mass = body.mass / body.n_points
	# for i in range(body.n_points):
	# 	if body.fixed[i]:
	# 		continue
	# 	body.points[i].linear_velocity.y += gravity * point_mass * delta
	# 	body.points[i].position += body.points[i].linear_velocity * delta


static func draw(node: Node2D, body, draw_points: bool=true, draw_connections: bool=true):
	if draw_points:
		for position in body.points:
			node.draw_circle(position.position, 1, Color.white)
	
	if draw_connections:
		for spring in body.spring:
			node.draw_line(body.points[spring[0]].position, body.points[spring[1]].position, Color.white)
