extends Node2D
class_name SoftBody2D


var auto_update: bool = true
var mass: float = 10
var gravity_vec: Vector2 = Vector2(0, 98)
var stiffness: float = 500
var damping_factor: float = 30
var self_collision_enabled: bool = true
var self_collision_distance: float = 1

var cloth_mode: bool = false

var points = []
var positions = []
var velocities = []
var fixed = []
var springs = []

# draw
var auto_draw: bool = false
var draw_points: bool = true
var draw_connections: bool = true
var draw_self_collision_circle: bool = false

var _redraw_required: bool = false

func _process(delta):
	if auto_draw and _redraw_required:
		_redraw_required = false
		update()

func _physics_process(delta):
	if auto_update:
		update_physics(delta)

func _draw():
	if draw_points:
		for position in points:
			draw_circle(position.position, 1, Color.white)

	if draw_self_collision_circle:
		for position in points:
			draw_circle(position.position, self_collision_distance / 2, Color8(128, 128, 128, 50))
	
	if draw_connections:
		for spring in springs:
			draw_line(points[spring[0]].position, points[spring[1]].position, Color.white)


func create(rows: int, columns: int, width: float, height: float, cloth: bool=false):
	points = []
	positions = []
	velocities = []
	fixed = []
	springs = []

	var dx = width / rows
	var dy = height / columns
	var dd = sqrt(dx * dx + dy * dy)

	self_collision_distance = min(dx, dy) * 0.8
	cloth_mode = cloth

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
			
			positions.append(Vector2(ri * dx, ci * dy))
			velocities.append(Vector2(0, 0))
			fixed.append(false)

			if ri < rows - 1:
				springs.append([ci * rows + ri, ci * rows + ri + 1, dx])
			if ci < columns - 1:
				springs.append([ci * rows + ri, ci * rows + ri + rows, dy])
				if cloth:
					continue

				if ri < rows - 1:
					springs.append([ci * rows + ri, ci * rows + ri + rows + 1, dd])
				if ri > 0:
					springs.append([ci * rows + ri, ci * rows + ri + rows - 1, dd])

	if not cloth:
		for i in range(rows * columns):
			for j in range(rows * columns):
				if i != j:
					points[i].add_collision_exception_with(points[j])
	
	
	for p in points:
		add_child(p)


func update_physics(delta):
	var n_points = len(points)
	if n_points == 0:
		return

	for spring in springs:
		var force = Vector2(0, 0)

		var relative_position = points[spring[1]].position - points[spring[0]].position
		var direction = relative_position.normalized()

		force += direction.dot(velocities[spring[1]] - velocities[spring[0]]) * direction * damping_factor

		force += (relative_position - relative_position.normalized() * spring[2]) * stiffness

		if not fixed[spring[0]]:
			velocities[spring[0]] += force * delta
		if not fixed[spring[1]]:
			velocities[spring[1]] -= force * delta

	if not cloth_mode:
		# self collision
		for i in range(n_points):
			for j in range(i + 1, n_points):
				var rel_pos = points[j].position - points[i].position

				var overlap_len = self_collision_distance - rel_pos.length()
				if overlap_len > 0:
					var dir = rel_pos.normalized()
					
					if not fixed[i]:
						points[i].position -= dir * overlap_len * 0.5
					
					if not fixed[j]:
						points[j].position += dir * overlap_len * 0.5

					var ivel = velocities[i]
					
					if dir.dot(velocities[j] - velocities[i]) < 0:
						velocities[i] -= dir * dir.dot(velocities[i]) - dir * dir.dot(velocities[j]) * 0.5
						velocities[j] -= dir * dir.dot(velocities[j]) - dir * dir.dot(ivel) * 0.5
	
		var point_mass = mass / n_points
		for i in range(n_points):
			if fixed[i]:
				continue
			velocities[i] += gravity_vec * delta
			
			var col = points[i].move_and_collide(velocities[i] * delta, false, true, true)
			
			if col:
				points[i].position += col.travel

				var surface_dir = col.normal.rotated(PI * 0.5)
				var collider_rel_pos = col.collider.position - col.position
				var collider_dir = collider_rel_pos.normalized()


				# slide
				points[i].position += surface_dir.dot(col.remainder) * surface_dir * 0.95


				if col.collider is RigidBody2D:
					var rel_vel = (col.travel + col.remainder) / delta + (col.position - points[i].global_position) * 3
					rel_vel -= col.collider.linear_velocity + collider_rel_pos.length() * col.collider.angular_velocity * collider_dir.rotated(-0.5 * PI)

					velocities[i] += col.normal * col.normal.dot(-col.remainder) / delta * (col.collider.mass / (point_mass + col.collider.mass))
					
					col.get_collider().linear_velocity += rel_vel
					col.get_collider().angular_velocity -= collider_dir.rotated(0.5 * PI).dot(rel_vel) / collider_rel_pos.length()
					
				else:
					velocities[i] = surface_dir * surface_dir.dot(velocities[i]) * 0.95
				
			else:
				points[i].position += velocities[i] * delta
	else:
		for i in range(n_points):
			if fixed[i]:
				continue
			velocities[i] += gravity_vec * delta
			points[i].position += velocities[i] * delta
	
	_redraw_required = true
