class_name RemoveEdgeCommand
extends RefCounted

var graph_manager: GraphManager
var from_id: String
var to_id: String
var old_label: String

func _init(manager: GraphManager, start: String, end: String):
	graph_manager = manager
	from_id = start
	to_id = end
	# Capture current state for undo
	old_label = ""
	for edge in graph_manager.edges:
		if edge["from"] == from_id and edge["to"] == to_id:
			old_label = edge.get("label", "")
			break

func execute():
	graph_manager.remove_edge(from_id, to_id)

func undo():
	graph_manager.add_edge(from_id, to_id, old_label)
