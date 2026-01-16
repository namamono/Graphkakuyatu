extends Node

const GRID_SIZE = 20.0
const NODE_RADIUS = 30.0
const DEFAULT_NODE_COLOR = Color(0.2, 0.6, 1.0)
const SELECTED_NODE_COLOR = Color(1.0, 0.6, 0.2)
const EDGE_COLOR = Color(0.8, 0.8, 0.8)
const EDGE_WIDTH = 2.0

var next_node_id = 0

func generate_node_id() -> String:
	next_node_id += 1
	return "node_%d" % next_node_id
