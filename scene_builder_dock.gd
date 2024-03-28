@tool
extends EditorPlugin

# Constant
var path_root : String = "res://Data/SceneBuilderCollections/"
var path_to_resource : String = "res://Data/SceneBuilderCollections/collection_names.tres"
var path_to_tmp_icon : String = "res://addons/SceneBuilder/icon_tmp.png"

# Updated by update_world_3d()
var editor : EditorInterface
var space : PhysicsDirectSpaceState3D
var world3d : World3D
var viewport : Viewport
var camera : Camera3D
var scene_root

var collection_names : Array
var item_collections : Dictionary
var tab_collection_buttons : Array

#region Dock controls

var scene_builder_dock : VBoxContainer
var tab_container : TabContainer

# Tab buttons
var btn_collection_01 : Button
var btn_collection_02 : Button
var btn_collection_03 : Button
var btn_collection_04 : Button
var btn_collection_05 : Button
var btn_collection_06 : Button
var btn_collection_07 : Button
var btn_collection_08 : Button
var btn_collection_09 : Button
var btn_collection_10 : Button
var btn_collection_11 : Button
var btn_collection_12 : Button

# User input - Placement
var btn_use_random_roatation : CheckButton
var btn_use_random_scale : CheckButton
var hslider_random_x_rotation : HSlider
var hslider_random_y_rotation : HSlider
var hslider_random_z_rotation : HSlider
var spinbox_min_x_scale : SpinBox
var spinbox_min_y_scale : SpinBox
var spinbox_min_z_scale : SpinBox
var spinbox_max_x_scale : SpinBox
var spinbox_max_y_scale : SpinBox
var spinbox_max_z_scale : SpinBox

# User input - Options
var btn_use_surface_normal : CheckButton
var btn_add_to_multi_mesh_instance : CheckButton
var btn_multi_select : CheckButton

# User input - Item
var btn_reload_all_items : Button

#endregion

func _enter_tree():
	editor = get_editor_interface()
	update_world_3d()
	
	# Dock
	scene_builder_dock = load("res://addons/SceneBuilder/scene_builder_dock.tscn").instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, scene_builder_dock)
	
	# Controls
	tab_container = scene_builder_dock.get_node("Collection/TabContainer")
	
	# Initialize custom tab buttons
	populate_collection_names_from_resource()
	tab_collection_buttons = [btn_collection_01, btn_collection_02, btn_collection_03, 
							  btn_collection_04, btn_collection_05, btn_collection_06, 
							  btn_collection_07, btn_collection_08, btn_collection_09,
							  btn_collection_10, btn_collection_11, btn_collection_12]
	var k : int = 0
	for tab_button : Button in tab_collection_buttons:
		k += 1
		tab_button = scene_builder_dock.get_node("Collection/Tab/%s" % k)
		tab_button.pressed.connect(on_custom_tab_button_pressed.bind(k))
		var collection_name = collection_names[k-1]
		if collection_name == "":
			collection_name = " "
		tab_button.text = collection_name
	
	reload_all_items()
	

func on_item_icon_clicked(_button_name : String):
	print("item clicked: ", _button_name)

func populate_collection_names_from_resource():
	var _names : CollectionNames = load(path_to_resource)
	if _names != null:
		
		collection_names.append(_names.collection_name_01)
		collection_names.append(_names.collection_name_02)
		collection_names.append(_names.collection_name_03)
		collection_names.append(_names.collection_name_04)
		collection_names.append(_names.collection_name_05)
		collection_names.append(_names.collection_name_06)
		collection_names.append(_names.collection_name_07)
		collection_names.append(_names.collection_name_08)
		collection_names.append(_names.collection_name_09)
		collection_names.append(_names.collection_name_10)
		collection_names.append(_names.collection_name_11)
		collection_names.append(_names.collection_name_12)
		
		# Validate
		for _name in collection_names:
			if _name != "":
				var dir = DirAccess.open(path_root + _name)
				if dir:
					dir.list_dir_begin()
					var item = dir.get_next()
					if item != "":
						print("Collection directory is present and contains items: " + _name)
					else:
						print("Error: directory exists, but contains no items: " + _name)
				else:
					print("Error: collection directory does not exist: " + _name)
	else:
		print("Error: collection names resource is null")

func get_items_from_collection_folder(_collection_name : String) -> Array:
	print("Collecting items from collection folder")
	
	var _items = []
	
	var dir = DirAccess.open(path_root + _collection_name + "/Item")
	if dir:
		dir.list_dir_begin()
		var item_filename = dir.get_next()
		while item_filename != "":
			if item_filename.ends_with(".tres"):
				var item_path = path_root + _collection_name + "/Item/" + item_filename
				var resource = load(item_path)
				if resource and resource is SceneBuilderItem:
					print("Loaded item: ", item_filename)
					_items.append(resource)
				else:
					print("The resource is not a SceneBuilderItem or failed to load: ", item_filename)
			item_filename = dir.get_next()

	return _items

func instantiate_at_cursor(path):
	var mouse_pos = viewport.get_mouse_position()
	
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is PackedScene:
			var scene : PackedScene = loaded
			
			var instance = scene.instantiate()
			
			var origin = camera.project_ray_origin(mouse_pos)
			var end = origin + camera.project_ray_normal(mouse_pos) * 1000
			var query = PhysicsRayQueryParameters3D.new()
			query.from = origin
			query.to = end
			var result : Dictionary = space.intersect_ray(query)
			
			var transform = Transform3D.IDENTITY
			if result and result.collider:
				transform.origin = result.position
			else:
				print("No hit")
			
			scene_root.add_child(instance)
			instance.owner = scene_root
			instance.global_transform = transform
			
			print("Instantiated: " + instance.name + " at " + str(instance.global_transform.origin))

func on_custom_tab_button_pressed(tab_index: int):
	tab_container.current_tab = tab_index-1

func update_world_3d():
	scene_root = editor.get_edited_scene_root()
	viewport = editor.get_editor_viewport_3d()
	world3d = viewport.find_world_3d()
	space = world3d.direct_space_state
	camera = viewport.get_camera_3d()

func reload_all_items():
	print("Loading items from all collections...")
	
	var i = 0
	for collection_name in collection_names:
		i += 1
		if collection_name != "" and DirAccess.dir_exists_absolute(path_root + "/%s" % collection_name):
			var grid_container : GridContainer = tab_container.get_node("%s/Grid" % i)
			
			item_collections[collection_name] = get_items_from_collection_folder(collection_name)
			
			print("Populating grid with icons")
			for item : SceneBuilderItem in item_collections[collection_name]:
				var texture_button : TextureButton = TextureButton.new()
				texture_button.texture_normal = item.icon  #load(path_to_tmp_icon)
				texture_button.pressed.connect(on_item_icon_clicked.bind(item.item_name))
				grid_container.add_child(texture_button)

func remove_all_items_from_dock():
	for i in range(1, 12):
		print("i: ", i)

func _exit_tree():
	remove_control_from_docks(scene_builder_dock)
	scene_builder_dock.queue_free()
