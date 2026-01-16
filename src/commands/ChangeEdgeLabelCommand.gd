class_name ChangeEdgeLabelCommand
extends RefCounted

var graph_manager: GraphManager
var from_id: String
var to_id: String
var old_label: String
var new_label: String

func _init(manager: GraphManager, fid: String, tid: String, old: String, new_l: String):
	graph_manager = manager
	from_id = fid
	to_id = tid
	old_label = old
	new_label = new_l

func execute():
	graph_manager.set_edge_label(from_id, to_id, new_label)

func undo():
	graph_manager.set_edge_label(from_id, to_id, old_label)
