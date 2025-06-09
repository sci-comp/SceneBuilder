@tool
extends EditorPlugin

func execute():
	var toolbox: SceneBuilderToolbox = SceneBuilderToolbox.new()

	var current_scene: Node = EditorInterface.get_edited_scene_root()
	var selection: EditorSelection = EditorInterface.get_selection()
	var selected_nodes: Array[Node] = selection.get_selected_nodes()

	print("[Temporary Debug] Empty")
