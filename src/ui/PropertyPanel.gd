extends Panel

signal label_changed(new_text)

@onready var label_edit = $VBoxContainer/LabelEdit
@onready var info_label = $VBoxContainer/InfoLabel

var current_id: String = ""
var is_node: bool = true
var target_manager: GraphManager

func setup(manager: GraphManager):
	target_manager = manager
	
func _ready():
	label_edit.text_submitted.connect(_on_text_submitted)
	label_edit.focus_exited.connect(func(): _on_text_submitted(label_edit.text))

func inspect_node(id: String):
	current_id = id
	is_node = true
	var node_data = target_manager.nodes.get(id, {})
	info_label.text = "Node: " + id
	label_edit.text = node_data.get("label", "")
	visible = true

func inspect_edge(from_id: String, to_id: String):
	# Composite key for edge?
	# We store edges as list in manager.
	# We need to find the specific edge data.
	for edge in target_manager.edges:
		if edge["from"] == from_id and edge["to"] == to_id:
			current_id = from_id + "->" + to_id # representation
			is_node = false
			info_label.text = "Edge: " + current_id
			label_edit.text = edge.get("label", "")
			# Store ids to identify later
			set_meta("from_id", from_id)
			set_meta("to_id", to_id)
			visible = true
			return

func clear_inspection():
	visible = false
	current_id = ""

func _on_text_submitted(new_text):
	if current_id == "": return
	
	if is_node:
		var old_label = target_manager.nodes[current_id]["label"]
		if old_label != new_text:
			# Should use Command for undo/redo
			# But for now, direct signal to Main or Manager?
			# Ideally Main handles "property changed" to wrap in Command.
			# But we emit signal 'label_changed' and let Main handle it.
			label_changed.emit(new_text)
	else:
		# Edge
		var from_id = get_meta("from_id")
		var to_id = get_meta("to_id")
		label_changed.emit(new_text)
