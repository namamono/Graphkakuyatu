class_name ChangeNodeLabelCommand
extends RefCounted

var graph_manager: GraphManager
var node_id: String
var old_label: String
var new_label: String

func _init(manager: GraphManager, id: String, old: String, new_l: String):
	graph_manager = manager
	node_id = id
	old_label = old
	new_label = new_l

func execute():
	graph_manager.set_node_label(node_id, new_label)

func undo():
	graph_manager.set_node_label(node_id, old_label)
