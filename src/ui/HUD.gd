extends Control

signal layout_requested
signal undo_requested
signal redo_requested
signal export_requested

func setup(cmd_manager):
	pass # Could display history stack size etc

func _on_layout_btn_pressed():
	layout_requested.emit()

func _on_undo_btn_pressed():
	undo_requested.emit()

func _on_redo_btn_pressed():
	redo_requested.emit()

func _on_export_btn_pressed():
	export_requested.emit()
