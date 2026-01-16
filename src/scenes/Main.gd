extends Node2D

var graph_manager: GraphManager
var command_manager: CommandManager
var layout_engine: LayoutEngine

@onready var nodes_layer = $NodesLayer
@onready var edges_layer = $EdgesLayer
@onready var camera = $Camera2D
@onready var hud = $HUDLayer/HUD
@onready var property_panel = $HUDLayer/PropertyPanel

var node_scene = preload("res://src/scenes/GraphNode.tscn")
var edge_scene = preload("res://src/scenes/Edge.tscn")

var is_panning = false
var zoom_speed = 0.1
var min_zoom = 0.1
var max_zoom = 5.0
var temp_edge_line: Line2D
var connecting_from_node_id: String = ""

# Track drag start for Move Command
var drag_start_pos: Vector2 = Vector2.ZERO
var dragging_node_id: String = ""

func _ready():
	graph_manager = GraphManager.new()
	command_manager = CommandManager.new()
	layout_engine = LayoutEngine.new()
	
	graph_manager.node_added.connect(_on_node_added_data)
	graph_manager.node_removed.connect(_on_node_removed_data)
	graph_manager.edge_added.connect(_on_edge_added_data)
	graph_manager.edge_removed.connect(_on_edge_removed_data)
	graph_manager.node_moved.connect(_on_node_moved_data)
	graph_manager.graph_updated.connect(_on_graph_updated) # Generic update for labels etc
	
	hud.setup(command_manager)
	hud.layout_requested.connect(_on_layout_requested)
	hud.undo_requested.connect(command_manager.undo)
	hud.redo_requested.connect(command_manager.redo)
	hud.export_requested.connect(_on_export_requested)
	
	# Visual/Input Priority: Nodes on top of Edges
	# Ensure NodesLayer is drawn AFTER EdgesLayer
	move_child(nodes_layer, -1)
	
	property_panel.setup(graph_manager)
	property_panel.label_changed.connect(_on_property_label_changed)
	
	temp_edge_line = Line2D.new()
	temp_edge_line.width = Global.EDGE_WIDTH
	temp_edge_line.default_color = Color(Global.EDGE_COLOR, 0.5)
	temp_edge_line.visible = false
	add_child(temp_edge_line)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var zoom = camera.zoom.x + 0.1
			camera.zoom = Vector2(zoom, zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var zoom = camera.zoom.x - 0.1
			if zoom < 0.1: zoom = 0.1
			camera.zoom = Vector2(zoom, zoom)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click and connecting_from_node_id == "":
				_create_node_at_mouse()
			elif event.pressed:
				_deselect_all_nodes()
				_deselect_all_edges()
				property_panel.clear_inspection()

	elif event is InputEventMouseMotion:
		if is_panning:
			camera.position -= event.relative / camera.zoom

func _input(event):
	# Handle global connection logic here (overlay)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if not event.pressed and connecting_from_node_id != "":
				_finish_connection(get_global_mouse_position())
	
	elif event is InputEventMouseMotion:
		if connecting_from_node_id != "":
			var start_pos = graph_manager.nodes.get(connecting_from_node_id, {}).get("position", Vector2.ZERO)
			temp_edge_line.points = [start_pos, get_global_mouse_position()]
			temp_edge_line.visible = true
			queue_redraw() # Request redraw for arrow if we draw it manually or via line

func _draw():
	# Draw arrow head if connecting
	if connecting_from_node_id != "" and temp_edge_line.points.size() > 1:
		var start = temp_edge_line.points[0]
		var end = temp_edge_line.points[1]
		var color = temp_edge_line.default_color
		var angle = (end - start).angle()
		var arrow_size = 15.0
		var arrow_points = PackedVector2Array([
			end + Vector2(-arrow_size, -arrow_size * 0.5).rotated(angle),
			end,
			end + Vector2(-arrow_size, arrow_size * 0.5).rotated(angle)
		])
		draw_polyline(arrow_points, color, 2.0)

func _create_node_at_mouse():
	var pos = get_global_mouse_position()
	var id = Global.generate_node_id()
	var cmd = AddNodeCommand.new(graph_manager, id, pos, id)
	command_manager.execute(cmd)

func _finish_connection(mouse_pos):
	temp_edge_line.visible = false
	queue_redraw()
	# Check if we released over a node
	# We need to find the node under mouse_pos visually
	var target_id = ""
	for child in nodes_layer.get_children():
		# Logic to detect if inside node radius/ellipse
		if child.has_method("is_point_inside"):
			if child.is_point_inside(mouse_pos):
				target_id = child.node_id
				break
		else:
			# Fallback
			if child.position.distance_to(mouse_pos) <= Global.NODE_RADIUS:
				target_id = child.node_id
				break
	
	if target_id != "" and target_id != connecting_from_node_id:
		# Check if edge already exists for toggle behavior
		var exists = false
		for e in graph_manager.edges:
			if e["from"] == connecting_from_node_id and e["to"] == target_id:
				exists = true
				break
		
		if exists:
			# Toggle: Remove it
			var cmd = RemoveEdgeCommand.new(graph_manager, connecting_from_node_id, target_id)
			command_manager.execute(cmd)
		else:
			# Add it
			var cmd = AddEdgeCommand.new(graph_manager, connecting_from_node_id, target_id)
			command_manager.execute(cmd)
	
	connecting_from_node_id = ""

func _on_node_added_data(id, data):
	var node_inst = node_scene.instantiate()
	nodes_layer.add_child(node_inst)
	node_inst.setup(id, data["label"])
	node_inst.position = data["position"]
	
	node_inst.dragged.connect(func(pos): _on_node_dragged(id, pos))
	node_inst.drag_start.connect(func(): _on_node_drag_start(id))
	node_inst.drag_end.connect(func(): _on_node_drag_end(id))
	node_inst.connection_request.connect(func(nid): _on_node_connection_request(nid))
	node_inst.node_selected.connect(_on_node_selected)

func _on_node_connection_request(id):
	connecting_from_node_id = id
	var start_pos = graph_manager.nodes[id]["position"]
	temp_edge_line.points = [start_pos, get_global_mouse_position()]
	temp_edge_line.visible = true
	temp_edge_line.width = 1.0 # Thin line

func _on_node_drag_start(id):
	dragging_node_id = id
	drag_start_pos = graph_manager.nodes[id]["position"]
	_on_node_selected(id) # Select when dragging starts too

func _on_node_dragged(id, pos):
	graph_manager.set_node_position(id, pos) # Emits moved
	
func _on_node_drag_end(id):
	if dragging_node_id == id:
		var final_pos = graph_manager.nodes[id]["position"]
		if final_pos.distance_to(drag_start_pos) > 1.0: 
			var cmd = MoveNodeCommand.new(graph_manager, id, drag_start_pos, final_pos)
			command_manager.execute(cmd)
		dragging_node_id = ""

func _on_node_removed_data(id):
	for child in nodes_layer.get_children():
		if child.node_id == id:
			child.queue_free()
			break

func _on_edge_added_data(from_id, to_id):
	var edge_inst = edge_scene.instantiate()
	edges_layer.add_child(edge_inst)
	var node_a = _find_node_visual(from_id)
	var node_b = _find_node_visual(to_id)
	var label = ""
	for e in graph_manager.edges:
		if e["from"] == from_id and e["to"] == to_id:
			label = e.get("label", "")
			break
			
	edge_inst.setup(node_a, node_b, label)
	edge_inst.set_meta("from", from_id)
	edge_inst.set_meta("to", to_id)
	edge_inst.set_meta("to", to_id)
	edge_inst.set_meta("to", to_id)
	edge_inst.edge_selected.connect(_on_edge_selected)

func _on_edge_removed_data(from_id, to_id):
	for child in edges_layer.get_children():
		if child.get_meta("from") == from_id and child.get_meta("to") == to_id:
			child.queue_free()
			break

func _on_node_moved_data(id, pos):
	var node_visual = _find_node_visual(id)
	if node_visual:
		if node_visual.position.distance_to(pos) > 0.1:
			node_visual.position = pos

func _find_node_visual(id):
	for child in nodes_layer.get_children():
		if child.node_id == id:
			return child
	return null

func _on_layout_requested():
	layout_engine.apply_layout(graph_manager, Vector2(0,0)) 

func _on_export_requested():
	var exporter = load("res://src/utils/DotExporter.gd").new()
	exporter.export_to_file(graph_manager, "user://output.dot") 

func _on_node_selected(id):
	# Deselect others
	_deselect_all_edges()
	_deselect_all_nodes(id)
	property_panel.inspect_node(id)

func _deselect_all_nodes(except_id = ""):
	for child in nodes_layer.get_children():
		if child.node_id != except_id:
			child.deselect()

func _on_edge_selected(from_id, to_id):
	_deselect_all_nodes()
	# Highlight specific edge and deselect others
	for child in edges_layer.get_children():
		if child.get_meta("from") == from_id and child.get_meta("to") == to_id:
			child.select()
		else:
			child.deselect()

	property_panel.inspect_edge(from_id, to_id)

func _deselect_all_edges():
	for child in edges_layer.get_children():
		child.deselect()

func _on_property_label_changed(new_text):
	if property_panel.is_node:
		var id = property_panel.current_id
		var old = graph_manager.nodes[id]["label"]
		var cmd = ChangeNodeLabelCommand.new(graph_manager, id, old, new_text)
		command_manager.execute(cmd)
	else:
		var from_id = property_panel.get_meta("from_id")
		var to_id = property_panel.get_meta("to_id")
		# Find old label
		var old = ""
		for edge in graph_manager.edges:
			if edge["from"] == from_id and edge["to"] == to_id:
				old = edge.get("label", "")
				break
		var cmd = ChangeEdgeLabelCommand.new(graph_manager, from_id, to_id, old, new_text)
		command_manager.execute(cmd)

func _on_graph_updated():
	# Update visuals if needed.
	# For labels, simpler to update all or just rely on 'graph_updated' signal to be broad
	# But nodes need to fetch new label.
	# Let's iterate.
	for child in nodes_layer.get_children():
		var data = graph_manager.nodes.get(child.node_id)
		if data:
			child.label.text = data["label"]
	
	# Detect bidirectional pairs for visual merging
	# We want to show ONE edge with TWO arrows if A->B and B->A exist.
	var edge_pairs = {} # Key: "min_max", Value: { "id_from_to": edge, ... }

	for child in edges_layer.get_children():
		child.visible = true # Reset visibility
		child.is_double_sided = false # Reset double sided
		
		# Reset label to original data (because we might have appended text previously)
		# But wait, we don't store original separately on instance. 
		# We must refetch from graph_manager each time or just rely on the label being correct from the loop above?
		# The loop above (lines ~282) sets label from data. So currently child.label.text IS clean data.
		# Good.
		
		var from = child.get_meta("from")
		var to = child.get_meta("to")
		var key = ""
		if from < to: key = from + "_" + to
		else: key = to + "_" + from # Sort key to pair them
		
		if not key in edge_pairs:
			edge_pairs[key] = []
		edge_pairs[key].append(child)
	
	for key in edge_pairs:
		var group = edge_pairs[key]
		if group.size() > 1:
			# Potential bidirectional match
			# Identify the two nodes involved from the first edge
			var first = group[0]
			var raw_from = first.get_meta("from")
			var raw_to = first.get_meta("to")
			
			# Define canonical order for checking
			var id_a = ""
			var id_b = ""
			if raw_from < raw_to:
				id_a = raw_from
				id_b = raw_to
			else:
				id_a = raw_to
				id_b = raw_from
			
			var forward_edge = null # A->B
			var backward_edge = null # B->A
			
			for e in group:
				if e.get_meta("from") == id_a and e.get_meta("to") == id_b:
					if forward_edge == null: forward_edge = e
					else: e.visible = false # Duplicate forward? Hide.
				elif e.get_meta("from") == id_b and e.get_meta("to") == id_a:
					if backward_edge == null: backward_edge = e
					else: e.visible = false # Duplicate backward? Hide.
			
			if forward_edge and backward_edge:
				# We have a pair. Merge into forward_edge.
				forward_edge.is_double_sided = true
				backward_edge.visible = false
				
				# Combine labels if they differ
				var t1 = forward_edge.label_text
				var t2 = backward_edge.label_text
				if t2 != "" and t2 != t1:
					if t1 != "":
						forward_edge.label.text = t1 + " / " + t2
					else:
						forward_edge.label.text = t2
					# Note: we are changing the VISUAL label, not the data.
					# Next update it resets. Correct.
				
	# Also update label text, it was removed from the loop above
	for child in edges_layer.get_children():
		var from = child.get_meta("from")
		var to = child.get_meta("to")
		# We need to find WHICH data corresponds to THIS child instance.
		# This is tricky because visual instances don't link 1:1 to data array indices directly.
		# They are just children.
		# Simplest way: iterate all edges data, finding matches, and consuming them?
		pass
	
	# Actually, re-syncing visuals to data is cleaner if we just rebuild OR assign carefully.
	# Main.gd listens to _on_edge_added_data which creates ONE child.
	# So children list is exactly synced with creation events.
	# But _on_graph_updated assumes update.
	# We need to map edges_layer children to graph_manager.edges.
	# Since create order is preserved (append), we can iterate both?
	# graph_manager.edges likely matches edges_layer child order provided no deletions/inserts shuffled things.
	# But deletions strictly remove by meta?
	
	# Safe approach: Re-assign all labels by iterating.
	# We have multiple edges A->B.
	# Data: [ {from:A,to:B,label:1}, {from:A,to:B,label:2} ]
	# Visuals: [ Line2D(A->B), Line2D(A->B) ]
	# We want mapping.
	# We can't distinguish by ID.
	# We just consume them.
	
	var edges_pool = graph_manager.edges.duplicate()
	for child in edges_layer.get_children():
		var c_from = child.get_meta("from")
		var c_to = child.get_meta("to")
		var found_idx = -1
		for i in range(edges_pool.size()):
			var e = edges_pool[i]
			if e["from"] == c_from and e["to"] == c_to:
				found_idx = i
				child.set_text(e.get("label", ""))
				break
		if found_idx != -1:
			edges_pool.remove_at(found_idx) # Consume so next visual gets next data
			
