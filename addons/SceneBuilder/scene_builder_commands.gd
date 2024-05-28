@tool
extends EditorPlugin

var submenu_scene: PopupMenu
var reusable_instance
var input_map

enum SceneCommands 
{
	alphabetize_nodes = 1,
	create_scene_builder_items = 10,
	instantiate_at_cursor = 30,
	instantiate_from_json = 31,
	instantiate_in_a_row = 32,
	make_local = 40,
	push_to_grid = 45,
	push_parent_offset_to_child = 46,
	reset_node_name = 50,
	reset_transform = 61,
	reset_transform_rotation = 62,
	select_children = 70,
	select_parents = 71,
	swap_nodes = 80,
	swap_nodes_in_scene = 81
}

func _unhandled_input(event: InputEvent):
	if event is InputEventKey:
		if event.is_pressed() and !event.is_echo():
			
			if event.alt_pressed:
				
				match event.keycode:
					input_map.create_scene_builder_items:
						create_scene_builder_items()
					input_map.alphabetize_nodes:
						alphabetize_nodes()
					input_map.make_local:
						make_local()
					input_map.push_to_grid:
						push_to_grid()
					input_map.push_parent_offset_to_child:
						push_parent_offset_to_child()
					input_map.reset_node_name:
						reset_node_name()
					input_map.swap_nodes:
						swap_nodes()
					input_map.reset_transform:
						reset_transform()
					input_map.reset_transform_rotation:
						reset_transform_rotation()
					input_map.swap_nodes_in_scene:
						swap_nodes_in_scene()
					input_map.instantiate_from_json:
						instantiate_from_json()
					input_map.instantiate_in_a_row_1:
						instantiate_in_a_row(1)
					input_map.instantiate_in_a_row_2:
						instantiate_in_a_row(2)
					input_map.instantiate_in_a_row_5:
						instantiate_in_a_row(5)
					
			elif event.ctrl_pressed:
				
				if event.keycode == KEY_RIGHT:
					select_children()
				elif event.keycode == KEY_LEFT:
					select_parents()

func _enter_tree():
	
	submenu_scene = PopupMenu.new()
	submenu_scene.connect("id_pressed", Callable(self, "_on_scene_submenu_item_selected"))
	add_tool_submenu_item("Scene Builder", submenu_scene)
	submenu_scene.add_item("Alphabetize nodes", SceneCommands.alphabetize_nodes)
	submenu_scene.add_item("Create scene builder items", SceneCommands.create_scene_builder_items)
	submenu_scene.add_item("Instantiate at cursor", SceneCommands.instantiate_at_cursor)
	submenu_scene.add_item("Make local", SceneCommands.make_local)
	submenu_scene.add_item("Push to grid", SceneCommands.push_to_grid)
	submenu_scene.add_item("Push parent offset to child", SceneCommands.push_parent_offset_to_child)
	submenu_scene.add_item("Reset node names", SceneCommands.reset_node_name)
	submenu_scene.add_item("Reset transform", SceneCommands.reset_transform)
	submenu_scene.add_item("Reset transform rotation", SceneCommands.reset_transform_rotation)
	submenu_scene.add_item("Select children", SceneCommands.select_children)
	submenu_scene.add_item("Select parents", SceneCommands.select_parents)
	submenu_scene.add_item("Swap nodes", SceneCommands.swap_nodes)
	submenu_scene.add_item("Swap nodes in scene", SceneCommands.swap_nodes_in_scene)

func _exit_tree():
	remove_tool_menu_item("Scene Builder")

func _on_scene_submenu_item_selected(id: int):
	match id:
		SceneCommands.alphabetize_nodes:
			alphabetize_nodes()
			
		SceneCommands.create_scene_builder_items:
			create_scene_builder_items()
		
		SceneCommands.make_local:
			make_local()
		SceneCommands.push_to_grid:
			push_to_grid()
		SceneCommands.push_parent_offset_to_child:
			push_parent_offset_to_child()
		SceneCommands.reset_node_name:
			reset_node_name()
		SceneCommands.reset_transform:
			reset_transform()
		SceneCommands.reset_transform_rotation:
			reset_transform_rotation()
		SceneCommands.select_children:
			select_children()
		SceneCommands.select_children:
			select_parents()
		SceneCommands.swap_nodes:
			swap_nodes()
		SceneCommands.swap_nodes_in_scene:
			swap_nodes_in_scene()
	
func alphabetize_nodes():
	var _instance = preload("./Commands/alphabetize_nodes.gd").new()
	_instance.execute()

func create_scene_builder_items():
	var reusable_instance = preload("./Commands/create_scene_builder_items.gd").new()
	add_child(reusable_instance)
	reusable_instance.done.connect(_on_reusable_instance_done)
	reusable_instance.execute()

func instantiate_at_cursor():
	var _instance = preload("./Commands/instantiate_at_cursor.gd").new()
	_instance.execute()

func instantiate_from_json():
	var _instance = preload("./Commands/instantiate_from_json.gd").new()
	_instance.execute()

func instantiate_in_a_row(_space):
	var _instance = preload("./Commands/instantiate_in_a_row.gd").new()
	_instance.execute(_space)

func make_local():
	var _instance = preload("./Commands/make_local.gd").new()
	_instance.execute()

func push_to_grid():
	var _instance = preload("./Commands/push_to_grid.gd").new()
	_instance.execute()

func push_parent_offset_to_child():
	var _instance = preload("./Commands/push_parent_offset_to_child.gd").new()
	_instance.execute()

func reset_node_name():
	var _instance = preload("./Commands/reset_node_name.gd").new()
	_instance.execute()

func reset_transform():
	var _instance = preload("./Commands/reset_transform.gd").new()
	_instance.execute()

func reset_transform_rotation():
	var _instance = preload("./Commands/reset_transform_rotation.gd").new()
	_instance.execute()

func select_children():
	var _instance = preload("./Commands/select_children.gd").new()
	_instance.execute()
	
func select_parents():
	var _instance = preload("./Commands/select_parents.gd").new()
	_instance.execute()

func swap_nodes():
	var _instance = preload("./Commands/swap_nodes.gd").new()
	_instance.execute()

func swap_nodes_in_scene():
	var _instance = preload("./Commands/swap_nodes_in_scene.gd").new()
	_instance.execute()

func update_input_map(new_input_map) -> void:
	input_map = new_input_map

# ------------------------------------------------------------------------------

func _on_reusable_instance_done():
	if reusable_instance != null:
		print("Freeing reusable instance")
		reusable_instance.queue_free()


