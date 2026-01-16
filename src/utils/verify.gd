extends SceneTree

func _init():
	print("Starting Verification Test...")
	
	# Setup
	var graph_manager = GraphManager.new()
	var command_manager = CommandManager.new()
	var layouter = LayoutEngine.new()
	var exporter = DotExporter.new()
	
	# Test 1: Add Node
	print("Test 1: Add Node")
	var cmd1 = AddNodeCommand.new(graph_manager, "n1", Vector2(100, 100))
	command_manager.execute(cmd1)
	assert(graph_manager.nodes.has("n1"), "Node n1 should exist")
	
	# Test 2: Add Edge
	print("Test 2: Add Edge")
	var cmd2 = AddNodeCommand.new(graph_manager, "n2", Vector2(200, 200))
	command_manager.execute(cmd2)
	var cmd3 = AddEdgeCommand.new(graph_manager, "n1", "n2")
	command_manager.execute(cmd3)
	assert(graph_manager.edges.size() == 1, "Should have 1 edge")
	
	# Test 3: Undo
	print("Test 3: Undo")
	command_manager.undo() # Undo add edge
	assert(graph_manager.edges.size() == 0, "Edge should be removed")
	command_manager.undo() # Undo add n2
	assert(not graph_manager.nodes.has("n2"), "Node n2 should be removed")
	
	# Test 4: Redo
	print("Test 4: Redo")
	command_manager.redo() # Redo add n2
	command_manager.redo() # Redo add edge
	assert(graph_manager.nodes.has("n2"), "Node n2 should exist again")
	assert(graph_manager.edges.size() == 1, "Edge should exist again")
	
	# Test 5: Layout
	print("Test 5: Layout")
	layouter.apply_layout(graph_manager, Vector2(0,0))
	print("Layout applied. n1 pos: ", graph_manager.nodes["n1"]["position"])
	
	# Test 6: Export
	print("Test 6: Export")
	var dot_content = exporter.export_to_string(graph_manager)
	print("DOT Output:\n", dot_content)
	assert("n1 -- n2" in dot_content or "n2 -- n1" in dot_content, "Edge should be in DOT Output")
	
	print("Verification Completed Successfully!")
	quit()
