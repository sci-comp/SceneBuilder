@tool
extends EditorPlugin
## Used to quickly navigate the scene tree.

func execute():
	var selection : EditorSelection = EditorInterface.get_selection()
	var selected_nodes : Array[Node] = selection.get_selected_nodes()

	if selected_nodes.is_empty():
		print("[Select Children] Selection is empty")
		return

	selection.clear()

	for node in selected_nodes:
		for child in node.get_children():
			selection.add_node(child)
