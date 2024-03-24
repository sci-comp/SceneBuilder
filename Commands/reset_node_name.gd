@tool
extends EditorPlugin

func get_all_node_names(_node):
	var _all_node_names = []
	for _child in _node.get_children():
		_all_node_names.append(_child.name)
		if _child.get_child_count() > 0:
			var _result = get_all_node_names(_child)
			for _item in _result:
				_all_node_names.append(_item)
	return _all_node_names

func execute():
	var editor = get_editor_interface()
	var editor_selection = editor.get_selection()
	var selected_nodes = editor_selection.get_selected_nodes()

	var all_names = get_all_node_names(get_editor_interface().get_edited_scene_root())
	
	var pattern = "\\w -n(\\d+)"
	var regex = RegEx.new()
	regex.compile(pattern)
	
	for node in selected_nodes:
		
		all_names = get_all_node_names(get_editor_interface().get_edited_scene_root())
		
		if node.scene_file_path:
			var path_name = node.scene_file_path.get_file().get_basename()
			
			if path_name in all_names:
				
				var new_scene_name = path_name
				var suffix_counter = 1
				
				var increment_until = true
				while(increment_until):
					var _new_name = new_scene_name + "-n" + str(suffix_counter)
					
					if _new_name in all_names:
						suffix_counter += 1
					else:
						increment_until = false
						new_scene_name = _new_name
					
					if suffix_counter > 2000:
						print("suffix_counter is greater than 2000. error?")
						increment_until = false
				
				node.name = new_scene_name
			else:
				node.name = path_name
			
		else:
			print("Passing over: " + node.name)
