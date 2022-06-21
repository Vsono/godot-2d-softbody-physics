
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
			var point = KinematicBody2D.new()
			if not cloth:
				var col_shape = CollisionShape2D.new()
				col_shape.shape = CircleShape2D.new()
				col_shape.shape.radius = 3
				point.add_child(col_shape)
			point.set_safe_margin(0.2)
			points.append(point)

			point.position = Vector2(ri * dx, ci * dy)
			point.set_safe_margin(0.01)
			
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

	if not cloth:
		for i in range(rows * columns):
			for j in range(rows * columns):
				if i != j:
					points[i].add_collision_exception_with(points[j])
	
	return {
		'stiffness': stiffness, 'damping_factor': damping_factor,
		'n_points': rows * columns, 'mass': float(mass),
		'position': position, 'velocity': velocity,
		'fixed': fixed, 'spring': spring, 'points': points,
		'cloth': cloth, 'self_collision_distance': min(dx, dy) * 0.8,
		'self_collision_enabled': true
	}

static func update(delta, body, gravity=98):
	for spring in body.spring:
		var force = Vector2(0, 0)

		var relative_position = body.points[spring[1]].position - body.points[spring[0]].position
		var direction = relative_position.normalized()

		force += direction.dot(body.velocity[spring[1]] - body.velocity[spring[0]]) * direction * body.damping_factor

		force += (relative_position - relative_position.normalized() * spring[2]) * body.stiffness

		if not body.fixed[spring[0]]:
			body.velocity[spring[0]] += force * delta
		if not body.fixed[spring[1]]:
			body.velocity[spring[1]] -= force * delta

	if not body.cloth:
		# self collision
		for i in range(body.n_points):
			for j in range(i + 1, body.n_points):
				var rel_pos = body.points[j].position - body.points[i].position

				var overlap_len = body.self_collision_distance - rel_pos.length()
				if overlap_len > 0:
					var dir = rel_pos.normalized()
					
					if not body.fixed[i]:
						body.points[i].position -= dir * overlap_len * 0.5
					
					if not body.fixed[j]:
						body.points[j].position += dir * overlap_len * 0.5

					var ivel = body.velocity[i]
					
					if dir.dot(body.velocity[j] - body.velocity[i]) < 0:
						body.velocity[i] -= dir * dir.dot(body.velocity[i]) - dir * dir.dot(body.velocity[j]) * 0.5
						body.velocity[j] -= dir * dir.dot(body.velocity[j]) - dir * dir.dot(ivel) * 0.5
	
		var point_mass = body.mass / body.n_points
		for i in range(body.n_points):
			if body.fixed[i]:
				continue
			body.velocity[i].y += gravity * delta
			
			var col = body.points[i].move_and_collide(body.velocity[i] * delta, false, true, true)
			
			if col:
				body.points[i].position += col.travel

				var surface_dir = col.normal.rotated(PI * 0.5)
				var collider_rel_pos = col.collider.position - col.position
				var collider_dir = collider_rel_pos.normalized()


				# slide
				body.points[i].position += surface_dir.dot(col.remainder) * surface_dir * 0.95


				if col.collider is RigidBody2D:
					var rel_vel = (col.travel + col.remainder) / delta + (col.position - body.points[i].global_position) * 3
					rel_vel -= col.collider.linear_velocity + collider_rel_pos.length() * col.collider.angular_velocity * collider_dir.rotated(-0.5 * PI)

					body.velocity[i] += col.normal * col.normal.dot(-col.remainder) / delta * (col.collider.mass / (point_mass + col.collider.mass))
					
					col.get_collider().linear_velocity += rel_vel
					col.get_collider().angular_velocity -= collider_dir.rotated(0.5 * PI).dot(rel_vel) / collider_rel_pos.length()
					


				else:
					body.velocity[i] = surface_dir * surface_dir.dot(body.velocity[i]) * 0.95
				
			else:
				body.points[i].position += body.velocity[i] * delta
	else:
		for i in range(body.n_points):
			if body.fixed[i]:
				continue
			body.velocity[i].y += gravity * delta
			body.points[i].position += body.velocity[i] * delta





static func draw(node: Node2D, body, draw_points: bool=true, draw_connections: bool=true, draw_self_collision_circle: bool=false):
	if draw_points:
		for position in body.points:
			node.draw_circle(position.position, 1, Color.white)

	if draw_self_collision_circle:
		for position in body.points:
			node.draw_circle(position.position, body.self_collision_distance / 2, Color8(128, 128, 128, 50))
	
	if draw_connections:
		for spring in body.spring:
			node.draw_line(body.points[spring[0]].position, body.points[spring[1]].position, Color.white)
