@tool
extends EditorPlugin

func execute():
	var toolbox : SceneBuilderToolbox = SceneBuilderToolbox.new()
	
	var editor : EditorInterface = get_editor_interface()
	var current_scene : Node = editor.get_edited_scene_root()
	var selection : EditorSelection = editor.get_selection()
	var selected_nodes : Array[Node] = selection.get_selected_nodes()
	
	print("[Temporary Debug] Empty")
