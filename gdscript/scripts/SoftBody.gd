
# position = [Vector2, ...]
# velocity = [Vector2, ...]
# fixed = [bool, ...]
# spring = [[index, index, length], ...]
static func create_softbody(rows: int, columns: int, width: float, height: float, cloth: bool=false, mass: float=10, stiffness: float = 1, damping_factor: float = 1) -> Dictionary:
	var position = []
	var velocity = []
	var fixed = []
	var spring = []

	var dx = width / rows
	var dy = height / columns
	var dd = sqrt(dx * dx + dy * dy)

	for ci in range(columns):
		for ri in range(rows):
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
		'fixed': fixed, 'spring': spring
	}


static func update_softbody(delta, body, gravity=9.8):
	for spring in body.spring:
		var force = Vector2(0, 0)

		var relative_position = body.position[spring[1]] - body.position[spring[0]]
		var direction = relative_position.normalized()

		force += direction.dot(body.velocity[spring[1]] - body.velocity[spring[0]]) * direction * body.damping_factor

		force += (relative_position - relative_position.normalized() * spring[2]) * body.stiffness

		if not body.fixed[spring[0]]:
			body.velocity[spring[0]] += force * delta
		if not body.fixed[spring[1]]:
			body.velocity[spring[1]] -= force * delta
	
	var point_mass = body.mass / body.n_points
	for i in range(body.n_points):
		if body.fixed[i]:
			continue
		body.velocity[i].y += gravity * point_mass * delta
		body.position[i] += body.velocity[i] * delta
