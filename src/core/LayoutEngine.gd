class_name LayoutEngine
extends RefCounted

var repulsive_force = 2000.0
var spring_length = 120.0
var spring_force = 0.1
var gravity = 0.05
var damping = 0.9
var iterations = 300
var time_step = 0.1

func apply_layout(graph_manager: GraphManager, center: Vector2):
	var nodes = graph_manager.nodes
	var edges = graph_manager.edges
	
	if nodes.size() == 0:
		return

	# Copy positions to temp dict to avoid modifying valid state during calculation intermediate steps if we animated it.
	# But here we do mostly instant layout or iterative.
	# Let's do instant layout for now. (Iterate many times then update)
	
	var positions = {}
	var velocities = {}
	var ids = nodes.keys()
	
	for id in ids:
		positions[id] = nodes[id]["position"]
		velocities[id] = Vector2.ZERO
		
	for i in range(iterations):
		var forces = {}
		for id in ids:
			forces[id] = Vector2.ZERO
			
		# Repulsion
		for j in range(ids.size()):
			var id_a = ids[j]
			for k in range(j + 1, ids.size()):
				var id_b = ids[k]
				var diff = positions[id_a] - positions[id_b]
				var dist = diff.length()
				if dist < 0.1: dist = 0.1
				
				var force = diff.normalized() * (repulsive_force / dist)
				forces[id_a] += force
				forces[id_b] -= force
		
		# Attraction
		for edge in edges:
			var id_a = edge["from"]
			var id_b = edge["to"]
			if id_a in positions and id_b in positions:
				var diff = positions[id_a] - positions[id_b]
				var dist = diff.length()
				
				var force = diff.normalized() * (dist - spring_length) * spring_force
				forces[id_b] += force
				forces[id_a] -= force
		
		# Gravity (Center Attraction)
		for id in ids:
			var diff = center - positions[id]
			# Weak pull to center
			forces[id] += diff * gravity

		# Update
		for id in ids:
			velocities[id] = (velocities[id] + forces[id] * time_step) * damping
			positions[id] += velocities[id] * time_step
			
	# Update GraphManager
	for id in ids:
		graph_manager.set_node_position(id, positions[id])
