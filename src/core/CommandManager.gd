class_name CommandManager
extends RefCounted

var history: Array = []
var redo_stack: Array = []
var max_history: int = 50

# Command interface: must have execute() and undo() methods
func execute(command):
	command.execute()
	history.append(command)
	redo_stack.clear()
	if history.size() > max_history:
		history.pop_front()

func undo():
	if history.is_empty():
		return
	var command = history.pop_back()
	command.undo()
	redo_stack.append(command)

func redo():
	if redo_stack.is_empty():
		return
	var command = redo_stack.pop_back()
	command.execute()
	history.append(command)
