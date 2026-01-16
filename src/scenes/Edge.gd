extends Line2D

signal edge_selected(from_id, to_id)

var from_node: Node2D
var to_node: Node2D
var label_text: String = ""
var _points: PackedVector2Array = PackedVector2Array()
var is_double_sided: bool = false

@onready var label = $Label
@onready var area = $Area2D
@onready var shape = $Area2D/CollisionShape2D

func setup(node_a: Node2D, node_b: Node2D, text: String = ""):
	from_node = node_a
	to_node = node_b
	label_text = text
	width = Global.EDGE_WIDTH
	default_color = Global.EDGE_COLOR
	if label:
		label.text = text
	update_position()

func select():
	default_color = Global.SELECTED_NODE_COLOR
	queue_redraw()

func set_text(text: String):
	label_text = text
	if label:
		label.text = text

var curve_offset: float = 0.0:
	set(value):
		curve_offset = value
		update_position()
		queue_redraw()

func update_position():
	if from_node and to_node:
		var p_start = from_node.position
		var p_end = to_node.position
		
		# Straight line
		if from_node.has_method("get_perimeter_point"):
			p_start = from_node.get_perimeter_point(p_end)
		if to_node.has_method("get_perimeter_point"):
			p_end = to_node.get_perimeter_point(p_start)
		
		_points = [p_start, p_end]
		
		if label:
			# Calculate offset "beside" the line
			var center = (p_start + p_end) / 2
			var dir = (p_end - p_start).normalized()
			var perp = Vector2(dir.y, -dir.x) # Perpendicular vector
			var offset_dist = 15.0 # Distance from line
			
			# Position label centered at the offset point
			label.position = center + perp * offset_dist - label.size / 2
		
		# Clear native points to disable built-in Line2D rendering
		points = PackedVector2Array()

		# Update Collision Shape for picking
		# Update Collision Shape for picking
		var hit_width = max(width, 10.0) # Thickness for clickability

		if curve_offset == 0.0:
			# Straight line: Use a rotated RectangleShape2D for thickness
			var shape_node = area.get_node_or_null("CollisionShape2D")
			if not shape_node:
				shape_node = CollisionShape2D.new()
				shape_node.name = "CollisionShape2D"
				area.add_child(shape_node)
			
			var rect = shape_node.shape as RectangleShape2D
			if not rect:
				rect = RectangleShape2D.new()
				shape_node.shape = rect
			
			# Calculate midpoint and rotation
			var mid = (p_start + p_end) / 2
			var diff = p_end - p_start
			var length = diff.length()
			var angle = diff.angle()
			
			rect.size = Vector2(length, hit_width)
			shape_node.position = mid
			shape_node.rotation = angle
			
			# Disable/Remove Polygon if exists
			var poly = area.get_node_or_null("CollisionPolygon2D")
			if poly: poly.queue_free()
			
		else:
			# Curved line: Use Polygon
			var polys = Geometry2D.offset_polyline(_points, hit_width / 2.0)
			
			if polys.size() > 0:
				var collider = area.get_node_or_null("CollisionPolygon2D")
				if not collider:
					collider = CollisionPolygon2D.new()
					collider.name = "CollisionPolygon2D"
					area.add_child(collider)
				collider.polygon = polys[0]
				
				# Remove Shape if exists (the straight one)
				var seg = area.get_node_or_null("CollisionShape2D")
				if seg: seg.queue_free()

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			edge_selected.emit(get_meta("from"), get_meta("to"))
			select() # Visual feedback immediately
			get_viewport().set_input_as_handled()

func _process(_delta):
	update_position()
	queue_redraw()

func _draw():
	if _points.size() < 2: return
	
	draw_polyline(_points, default_color, width)
	
	# Last segment for direction
	var p_last = _points[_points.size() - 1]
	var p_prev = _points[_points.size() - 2]
	var dir = (p_last - p_prev).normalized()
	
	# Draw Standard Arrow (End)
	var arrow_size = 12.0
	var arrow_angle = deg_to_rad(30)
	
	# End Arrow
	if to_node:
		var tip = p_last
		var dir_end = (p_last - p_prev).normalized()
		var p1 = tip - dir_end.rotated(arrow_angle) * arrow_size
		var p2 = tip - dir_end.rotated(-arrow_angle) * arrow_size
		draw_colored_polygon(PackedVector2Array([p1, tip, p2]), default_color)

	# Start Arrow (if double sided)
	if is_double_sided and from_node:
		var p_first = _points[0]
		var p_second = _points[1]
		var tip = p_first
		var dir_start = (p_first - p_second).normalized() 
		var p1 = tip - dir_start.rotated(arrow_angle) * arrow_size
		var p2 = tip - dir_start.rotated(-arrow_angle) * arrow_size
		draw_colored_polygon(PackedVector2Array([p1, tip, p2]), default_color)

func deselect():
	default_color = Global.EDGE_COLOR
