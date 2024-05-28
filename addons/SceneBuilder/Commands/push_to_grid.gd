@tool
extends EditorPlugin

func execute():
	
	var grid_size : float = 1.0
	
	var selection: EditorSelection = get_editor_interface().get_selection()
	for selected: Node3D in selection.get_selected_nodes():
		selected.position.x = round(selected.position.x / grid_size) * grid_size
		selected.position.y = round(selected.position.y / grid_size) * grid_size
		selected.position.z = round(selected.position.z / grid_size) * grid_size

