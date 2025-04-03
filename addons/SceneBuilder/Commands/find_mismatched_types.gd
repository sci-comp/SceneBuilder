@tool
extends EditorPlugin
## Check for script class_name issues in the current scene

func execute():
	var root = EditorInterface.get_edited_scene_root()
	if not root:
		print("No scene is currently open.")
		return
	
	print("Checking scene for script class/base class mismatches...")
	check_node_and_children(root)
	print("Finished checking scene.")

func check_node_and_children(node):
	check_node(node)
	
	for i in node.get_child_count():
		var child = node.get_child(i)
		check_node_and_children(child)

func check_node(node):
	var script = node.get_script()
	if not script:
		return
	
	var node_class = node.get_class()
	var script_base = script.get_instance_base_type()
	
	if script is CSharpScript:
		if node_class != script_base:
			print("MISMATCH: Node '%s' is of type '%s', but attached script has base type '%s'" % [node.name, node_class, script_base])
	elif script is GDScript:
		# Not sure how to test for a mismatch.. does GDScript even throw errors here?
		print("GDScript found, skipping... ", node.name)
