''' Takes the absolute value of transform scale values. '''

@tool
extends EditorPlugin

func execute():
	
	var editor : EditorInterface = get_editor_interface()
	var undo_redo : EditorUndoRedoManager = get_undo_redo()
	var current_scene : Node = editor.get_edited_scene_root()
	var selection : EditorSelection = editor.get_selection()
	var selected_nodes : Array[Node] = selection.get_selected_nodes()
	
	if selected_nodes.is_empty():
		return
	
	undo_redo.create_action("Fix negative scaling")

	for selected: Node3D in selected_nodes:
		
		var new_scale : Vector3 = selected.scale
		if selected.scale.x < 0 || selected.scale.y < 0 || selected.scale.z < 0:
			new_scale = abs(selected.scale)
			print("Negative scale found for: ", selected.name)
		
		undo_redo.add_do_method(selected, "set_scale", new_scale)
		undo_redo.add_undo_method(selected, "set_scale", selected.scale)

	undo_redo.commit_action()
