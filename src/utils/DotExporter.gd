class_name DotExporter
extends RefCounted

func export_to_string(graph_manager: GraphManager) -> String:
	var output = "digraph G {\n"
	output += "\tgraph [bb=\"0,0,1000,1000\"];\n" # Optional bounding box
	output += "\tnode [shape=circle, fixedsize=true, width=0.6];\n" # Match approximate visual size
	
	# Coordinate conversion:
	# Godot: (0,0) at top-left, Y increases down.
	# Graphviz: (0,0) at bottom-left, Y increases up.
	# To preserve relative layout, we can just flip Y.
	# Or assume an arbitrary height, e.g. 1000.
	
	for id in graph_manager.nodes.keys():
		var node = graph_manager.nodes[id]
		var pos = node["position"]
		# Convert pos. Scale? 1 px = 1 pt?
		# Graphviz positions in points (1/72 inch). 
		# Let's assume 1:1 mapping for simplicity.
		# Flip Y. Let's shift origin to center or keep as is with flipped Y.
		# Ideally find min/max Y to keep positive coords.
		var dot_x = pos.x
		var dot_y = -pos.y # Flip Y
		var label = node["label"]
		
		# "pos" attribute with "!" forces position
		output += "\t%s [label=\"%s\", pos=\"%.2f,%.2f!\"];\n" % [id, label, dot_x, dot_y]
		
	for edge in graph_manager.edges:
		var label = edge.get("label", "")
		if label != "":
			output += "\t%s -> %s [label=\"%s\"];\n" % [edge["from"], edge["to"], label]
		else:
			output += "\t%s -> %s;\n" % [edge["from"], edge["to"]]
		
	output += "}\n"
	return output

func export_to_file(graph_manager: GraphManager, path: String):
	var content = export_to_string(graph_manager)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
		print("Exported to ", path)
		OS.shell_open(ProjectSettings.globalize_path(path)) # Open for user to see
	else:
		printerr("Failed to open file for writing: ", path)
