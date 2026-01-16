class_name AddNodeCommand
extends RefCounted

var graph_manager: GraphManager
var node_id: String
var position: Vector2
var label: String

func _init(manager: GraphManager, id: String, pos: Vector2, lbl: String = ""):
	graph_manager = manager
	node_id = id
	position = pos
	label = lbl

func execute():
	graph_manager.add_node(node_id, position, label)

func undo():
	graph_manager.remove_node(node_id)
