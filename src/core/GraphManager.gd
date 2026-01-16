class_name GraphManager
extends RefCounted

signal graph_updated
signal node_added(node_id, data)
signal node_removed(node_id)
signal edge_added(from_id, to_id)
signal edge_removed(from_id, to_id)
signal node_moved(node_id, new_pos)

# Format: { node_id: { "position": Vector2, "label": String } }
var nodes: Dictionary = {}

# Format: [ { "from": id, "to": id } ]
# To optimize, we might want an adjacency list too, but for small graphs simpler is fine.
var edges: Array = []

func add_node(id: String, position: Vector2, label: String = ""):
	if id in nodes:
		return
	if label == "":
		label = id
	nodes[id] = {
		"position": position,
		"label": label
	}
	node_added.emit(id, nodes[id])
	graph_updated.emit()

func remove_node(id: String):
	if not id in nodes:
		return
	
	# Remove connected edges
	var edges_to_remove = []
	for edge in edges:
		if edge["from"] == id or edge["to"] == id:
			edges_to_remove.append(edge)
	
	for edge in edges_to_remove:
		remove_edge(edge["from"], edge["to"])
		
	nodes.erase(id)
	node_removed.emit(id)
	graph_updated.emit()

func add_edge(from_id: String, to_id: String, label: String = ""):
	if from_id == to_id:
		return # No self-loops for now, usually
	if not (from_id in nodes and to_id in nodes):
		return
	
	# Check duplicate -> Removed to allow multigraph
	# for edge in edges:
	# 	if edge["from"] == from_id and edge["to"] == to_id:
	# 		return

	edges.append({ "from": from_id, "to": to_id, "label": label })
	edge_added.emit(from_id, to_id)
	graph_updated.emit()

func remove_edge(from_id: String, to_id: String):
	var target_index = -1
	for i in range(edges.size()):
		if edges[i]["from"] == from_id and edges[i]["to"] == to_id:
			target_index = i
			break
	
	if target_index != -1:
		edges.remove_at(target_index)
		edge_removed.emit(from_id, to_id)
		graph_updated.emit()

func set_node_position(id: String, position: Vector2):
	if id in nodes:
		nodes[id]["position"] = position
		node_moved.emit(id, position)

func set_node_label(id: String, text: String):
	if id in nodes:
		nodes[id]["label"] = text
		graph_updated.emit()

func set_edge_label(from_id: String, to_id: String, text: String):
	for edge in edges:
		if edge["from"] == from_id and edge["to"] == to_id:
			edge["label"] = text
			graph_updated.emit()
			break
