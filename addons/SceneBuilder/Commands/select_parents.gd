@tool
extends EditorPlugin
## Used to quickly navigate the scene tree.

func execute():
	var selection: EditorSelection = EditorInterface.get_selection()
	var selected_nodes: Array[Node] = selection.get_selected_nodes()

	if selected_nodes.is_empty():
		print("[Select Parents] Selection is empty")
		return

	selection.clear()

	for node in selected_nodes:
		var parent = node.get_parent()

		if parent:
			selection.add_node(parent)
