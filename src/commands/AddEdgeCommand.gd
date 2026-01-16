class_name AddEdgeCommand
extends RefCounted

var graph_manager: GraphManager
var from_id: String
var to_id: String

func _init(manager: GraphManager, start: String, end: String):
	graph_manager = manager
	from_id = start
	to_id = end

func execute():
	graph_manager.add_edge(from_id, to_id)

func undo():
	graph_manager.remove_edge(from_id, to_id)
