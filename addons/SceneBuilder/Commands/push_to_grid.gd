''' Round the position of selected nodes to the nearest whole grid value. '''

@tool
extends EditorPlugin

func execute():
	
	var editor : EditorInterface = get_editor_interface()
	var undo_redo : EditorUndoRedoManager = get_undo_redo()
	
	var selection : EditorSelection = editor.get_selection()
	var selected_nodes : Array[Node] = selection.get_selected_nodes()

	if selected_nodes.is_empty():
		return
	
	undo_redo.create_action("Snap to Grid")
	
	var grid_size : float = 0.25  # Todo: this should be adjustable by the user
	
	for selected: Node3D in selected_nodes:
		var old_pos = selected.position
		var new_pos = Vector3(
			round(selected.position.x / grid_size) * grid_size,
			round(selected.position.y / grid_size) * grid_size,
			round(selected.position.z / grid_size) * grid_size
		)
		
		undo_redo.add_do_property(selected, "position", new_pos)
		undo_redo.add_undo_property(selected, "position", old_pos)
	
	undo_redo.commit_action()

