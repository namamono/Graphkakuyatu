class_name MoveNodeCommand
extends RefCounted

var graph_manager: GraphManager
var node_id: String
var old_pos: Vector2
var new_pos: Vector2

func _init(manager: GraphManager, id: String, old: Vector2, new_p: Vector2):
	graph_manager = manager
	node_id = id
	old_pos = old
	new_pos = new_p

func execute():
	graph_manager.set_node_position(node_id, new_pos)

func undo():
	graph_manager.set_node_position(node_id, old_pos)
