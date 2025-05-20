@tool
extends EditorPlugin
## Sets visibility for all selected nodes based on the first selected node.
## If the first node is visible, all nodes will be made invisible, and vice versa.

func execute():
	var undo_redo: EditorUndoRedoManager = get_undo_redo()
	var selection: EditorSelection = EditorInterface.get_selection()
	var selected_nodes: Array[Node] = selection.get_selected_nodes()

	if selected_nodes.is_empty():
		return

	# Determine target visibility based on first node
	var first_visible = false
	if "visible" in selected_nodes[0]:
		first_visible = selected_nodes[0].visible
	
	# Target visibility is opposite of first node's visibility
	var target_visible = !first_visible
	
	undo_redo.create_action("Set Visibility")
	
	for node in selected_nodes:
		if "visible" in node:
			undo_redo.add_do_property(node, "visible", target_visible)
			undo_redo.add_undo_property(node, "visible", node.visible)
	
	undo_redo.commit_action()
