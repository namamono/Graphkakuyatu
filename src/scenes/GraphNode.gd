extends Node2D

signal dragged(new_pos)
signal drag_start
signal drag_end
signal node_selected(node_id)
signal connection_request(node_id) # On Shift+Click

var node_id: String = ""
var label_text: String = ""
var is_selected: bool = false
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

@onready var label = $Label

func setup(id: String, text: String):
	node_id = id
	label_text = text
	if label:
		label.text = text

@onready var area = $Area2D

func _ready():
	if label:
		label.text = label_text
		label.resized.connect(update_visuals)
	update_visuals()

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_dragging = true
			is_selected = true
			node_selected.emit(node_id)
			drag_start.emit()
			drag_offset = position - event.global_position
			update_visuals()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			connection_request.emit(node_id)
			get_viewport().set_input_as_handled()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if is_dragging:
				is_dragging = false
				drag_end.emit()
				update_visuals()

	elif event is InputEventMouseMotion:
		if is_dragging:
			position = event.global_position + drag_offset
			dragged.emit(position)
			get_viewport().set_input_as_handled()

func deselect():
	is_selected = false
	update_visuals()

var radius_x: float = Global.NODE_RADIUS
var radius_y: float = Global.NODE_RADIUS

func update_visuals():
	# Calculate size based on label
	if label:
		# Force resize to minimum content size
		label.size = Vector2.ZERO 
		var size = label.get_minimum_size()
		# Padding
		var padding_x = 10.0
		var padding_y = 8.0
		var min_r = Global.NODE_RADIUS
		
		# For very short text, allow smaller node
		if label.text.length() <= 2:
			min_r = 20.0
			
		var target_rx = max(min_r, size.x / 2.0 + padding_x)
		var target_ry = max(min_r, size.y / 2.0 + padding_y)
		
		# Force circle if dimensions are similar (square-ish label) or small.
		# This handles "short text" which creates a roughly square label.
		# Also explicitly check string length to force circle for short distinct labels like "a" or "1".
		if label.text.length() <= 2 or abs(target_rx - target_ry) < 20.0 or (target_rx < Global.NODE_RADIUS * 1.5):
			var max_r = max(target_rx, target_ry)
			target_rx = max_r
			target_ry = max_r
		
		radius_x = target_rx
		radius_y = target_ry
		
		# Update Label pos
		label.position = -size / 2.0
	
	# Update Collision Shape
	var col_shape = $Area2D/CollisionShape2D
	if col_shape and col_shape.shape is CircleShape2D:
		# Use scale to simulate ellipse
		# Base radius of CircleShape2D_node is 30.0
		col_shape.scale = Vector2(radius_x / 30.0, radius_y / 30.0)

	queue_redraw()

func is_point_inside(global_point: Vector2) -> bool:
	# Add a larger buffer for easier clicking
	var local = to_local(global_point)
	var dx = local.x
	var dy = local.y
	# Use HIT_RADIUS slightly larger effectively
	var a = radius_x + 20.0 
	var b = radius_y + 20.0
	
	if a == 0 or b == 0: return false
	
	return (dx*dx)/(a*a) + (dy*dy)/(b*b) <= 1.0

func get_perimeter_point(target_global_pos: Vector2) -> Vector2:
	var local_target = to_local(target_global_pos)
	var dir = local_target
	
	if dir.length_squared() < 0.001:
		return global_position + Vector2(radius_x, 0)
	
	# Ellipse Intersection: k = 1 / sqrt( dx^2/a^2 + dy^2/b^2 )
	var dx = dir.x
	var dy = dir.y
	var a = radius_x
	var b = radius_y
	
	var term = (dx*dx)/(a*a) + (dy*dy)/(b*b)
	if term <= 0: return global_position
	
	var k = 1.0 / sqrt(term)
	return to_global(dir * k)

func _draw():
	var color = Global.DEFAULT_NODE_COLOR
	if is_selected:
		color = Global.SELECTED_NODE_COLOR
	
	# Draw Ellipse
	# Godot 4 doesn't have draw_ellipse with fill directly?
	# We can use draw_colored_polygon or draw_arc loop.
	# Polygons are better.
	var nb_points = 32
	var points = PackedVector2Array()
	for i in range(nb_points):
		var angle = i * TAU / nb_points
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	
	draw_colored_polygon(points, color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.BLACK, 2.0)
