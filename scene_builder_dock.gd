@tool
extends EditorPlugin

# Constant
var path_root : String = "res://Data/SceneBuilderCollections/"
var path_to_resource : String = "res://Data/SceneBuilderCollections/collection_names.tres"
var path_to_tmp_icon : String = "res://addons/SceneBuilder/icon_tmp.png"
var path_to_solid_white_texture = "res://addons/StandardAssets/Texture/Common/T_Solid_White.png"
var btns_collection_tabs : Array = []  # set in _enter_tree()
var toolbox : SceneBuilderToolbox

#region Dock control elements

var scene_builder_dock : VBoxContainer
var tab_container : TabContainer

# Tabs
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

# Options
var btn_use_surface_normal : CheckButton
var btn_add_to_multi_mesh_instance : CheckButton
var btn_find_world_3d : Button
var btn_reload_all_items : Button

#endregion

# Updated by update_world_3d()
# Todo: This needs to be called on root scene change 
var editor : EditorInterface
var space : PhysicsDirectSpaceState3D
var world3d : World3D
var viewport : Viewport
var camera : Camera3D
var scene_root : Node3D

# Updated when reloading all collections
var collection_names : Array[String] = []
var items_by_collection : Dictionary = {}
var item_highlighters_by_collection : Dictionary = {}
# Also updated on tab button click
var current_collection : Dictionary = {}
var current_collection_name : String = ""
# Also updated on item click
var current_item : SceneBuilderItem = null
var current_item_name : String = ""
var current_instance : Node3D = null
var current_instance_rid_array : Array[RID] = []

# Assorted variables
var placement_mode_enabled : bool = false
var scene_builder_temp_node : Node

# ---- Notifications -----------------------------------------------------------

func _enter_tree():
	
	#
	editor = get_editor_interface()
	toolbox = SceneBuilderToolbox.new()
	
	#
	update_world_3d()
	
	# Initialize controls
	scene_builder_dock = load("res://addons/SceneBuilder/scene_builder_dock.tscn").instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, scene_builder_dock)
	tab_container = scene_builder_dock.get_node("Collection/TabContainer")
	btns_collection_tabs = [btn_collection_01, btn_collection_02, btn_collection_03, 
							btn_collection_04, btn_collection_05, btn_collection_06, 
							btn_collection_07, btn_collection_08, btn_collection_09,
							btn_collection_10, btn_collection_11, btn_collection_12]
	var k : int = 0
	for tab_button : Button in btns_collection_tabs:
		k += 1
		tab_button = scene_builder_dock.get_node("Collection/Tab/%s" % k)
		tab_button.pressed.connect(on_custom_tab_button_pressed.bind(k))
	btn_use_surface_normal = scene_builder_dock.get_node("Settings/Options/UseSurfaceNormal")
	btn_add_to_multi_mesh_instance = scene_builder_dock.get_node("Settings/Options/UseMultiMeshInstance")
	btn_find_world_3d = scene_builder_dock.get_node("Settings/Options/FindWorld3D")
	btn_reload_all_items = scene_builder_dock.get_node("Settings/Options/ReloadAllItems")
	btn_use_surface_normal.pressed.connect(on_use_surface_normal_clicked)
	btn_add_to_multi_mesh_instance.pressed.connect(on_use_multi_mesh_instance_clicked)
	btn_find_world_3d.pressed.connect(update_world_3d)
	btn_reload_all_items.pressed.connect(reload_all_items)
	
	#
	refresh_collection_names()
	
	#
	reload_all_items()

func _exit_tree():
	remove_control_from_docks(scene_builder_dock)
	scene_builder_dock.queue_free()

func _process(delta: float) -> void:
	if placement_mode_enabled:
		update_temporary_item_position()

func forward_3d_gui_input(_camera : Camera3D, event : InputEvent):
	
	if event is InputEventMouseButton and placement_mode_enabled:
		if event.is_pressed() and !event.is_echo():
			
			var mouse_pos = viewport.get_mouse_position()
			if mouse_pos.x >= 0 and mouse_pos.y >= 0: 
				if mouse_pos.x <= viewport.size.x and mouse_pos.y <= viewport.size.y:
					
					if event.button_index == MOUSE_BUTTON_LEFT:
						instantiate_current_item_at_position()
					
					if event.button_index == MOUSE_BUTTON_RIGHT:
						toggle_placement_mode()
					
				else:
					printerr("Mouse position is out of bounds, not possible?")
			else:
				printerr("Mouse position is out of bounds, not possible?")
		
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS

# ---- Buttons -----------------------------------------------------------------

func on_custom_tab_button_pressed(tab_index: int):
	tab_container.current_tab = tab_index-1
	current_collection_name = collection_names[tab_index-1]
	
	if current_collection_name == "" or current_collection_name == " ":
		current_collection = {}
	else:
		current_collection = items_by_collection[current_collection_name]
	
	placement_mode_enabled = false
	current_item_name = ""
	current_item = null

func on_item_icon_clicked(_button_name: String) -> void:
	
	var item_highlighters : Dictionary = item_highlighters_by_collection[current_collection_name]
	
	if placement_mode_enabled:
		# De-highlight current
		var current_nine_path : NinePatchRect = item_highlighters[current_item_name]
		current_nine_path.self_modulate = Color.BLACK
	
	if current_item_name != _button_name:
		# Highlight next
		var nine_path : NinePatchRect = item_highlighters[_button_name]
		nine_path.self_modulate = Color.GREEN
		
		current_item_name = _button_name
		placement_mode_enabled = true
		current_item = current_collection[current_item_name]
		create_temporary_item_instance()
	else:
		toggle_placement_mode()

func on_use_surface_normal_clicked():
	print("Todo: on_use_surface_normal_clicked")

func on_use_multi_mesh_instance_clicked():
	print("Todo: on_use_multi_mesh_instance_clicked")

func reload_all_items():
	
	print("Freeing all texture buttons")
	for i in range(1, 13):
		var grid_container : GridContainer = tab_container.get_node("%s/Grid" % i)
		for _node in grid_container.get_children():
			_node.queue_free()
	
	refresh_collection_names()
	
	print("Loading all items from all collections")
	var i = 0
	for collection_name in collection_names:
		i += 1
		if collection_name != "" and DirAccess.dir_exists_absolute(path_root + "/%s" % collection_name):
			var grid_container : GridContainer = tab_container.get_node("%s/Grid" % i)
			
			var item_dict : Dictionary = get_items_from_collection_folder(collection_name)
			var item_keys = item_dict.keys()
			items_by_collection[collection_name] = item_dict
			item_highlighters_by_collection[collection_name] = {}
			print("Populating grid with icons")
			for key : String in item_dict.keys():
				var item : SceneBuilderItem = item_dict[key]
				var texture_button : TextureButton = TextureButton.new()
				texture_button.toggle_mode = true
				texture_button.texture_normal = item.icon
				texture_button.tooltip_text = item.item_name
				texture_button.pressed.connect(on_item_icon_clicked.bind(item.item_name))
				grid_container.add_child(texture_button)
				
				var nine_patch : NinePatchRect = NinePatchRect.new()
				nine_patch.texture = CanvasTexture.new()
				nine_patch.draw_center = false
				nine_patch.set_anchors_preset(Control.PRESET_FULL_RECT)
				nine_patch.patch_margin_left = 4
				nine_patch.patch_margin_top = 4
				nine_patch.patch_margin_right = 4
				nine_patch.patch_margin_bottom = 4
				nine_patch.self_modulate = Color("000000")  # black  # 6a9d2e green
				item_highlighters_by_collection[collection_name][key] = nine_patch
				texture_button.add_child(nine_patch)

func update_world_3d():
	scene_root = editor.get_edited_scene_root()
	viewport = editor.get_editor_viewport_3d()
	world3d = viewport.find_world_3d()
	space = world3d.direct_space_state
	camera = viewport.get_camera_3d()
	
	if scene_root == null:
		printerr("scene_root not found")

# ---- Helpers -----------------------------------------------------------------

func clear_scene_builder_temp() -> void:
	
	if scene_root == null:
		printerr("scene_root is null inside clear_scene_builder_temp")
		return
	
	var temp_node = scene_root.get_node_or_null("SceneBuilderTemp")
	if temp_node:
		for child in temp_node.get_children():
			child.queue_free()

func create_temporary_item_instance() -> void:
	
	if scene_root == null:
		printerr("scene_root is null inside create_temporary_item_instance")
		return
	
	clear_scene_builder_temp() 
	scene_builder_temp_node = scene_root.get_node_or_null("SceneBuilderTemp")
	if not scene_builder_temp_node:
		scene_builder_temp_node = Node.new()
		scene_builder_temp_node.name = "SceneBuilderTemp"
		scene_root.add_child(scene_builder_temp_node)
		scene_builder_temp_node.owner = scene_root
	current_instance = current_item.item.instantiate()
	scene_builder_temp_node.add_child(current_instance)
	current_instance.owner = scene_root

func get_items_from_collection_folder(_collection_name : String) -> Dictionary:
	print("Collecting items from collection folder")
	
	var _items = {}
	
	var dir = DirAccess.open(path_root + _collection_name + "/Item")
	if dir:
		dir.list_dir_begin()
		var item_filename = dir.get_next()
		while item_filename != "":
			if item_filename.ends_with(".tres"):
				var item_path = path_root + _collection_name + "/Item/" + item_filename
				var resource = load(item_path)
				if resource and resource is SceneBuilderItem:
					var scene_builder_item : SceneBuilderItem = resource
					if ResourceLoader.exists(scene_builder_item.scene_path):
						var loaded = load(scene_builder_item.scene_path)
						if loaded is PackedScene:
							var _packed_scene : PackedScene = loaded
							scene_builder_item.item = _packed_scene
						else:
							printerr("Failed to instantiate packed scene: ", loaded.name)
					else:
						printerr("Path does not exist: ", scene_builder_item.scene_path)
					
					print("Loaded item: ", item_filename)
					
					_items[scene_builder_item.item_name] = scene_builder_item
				else:
					print("The resource is not a SceneBuilderItem or failed to load: ", item_filename)
			item_filename = dir.get_next()

	return _items

func get_all_node_names(_node):
	var _all_node_names = []
	for _child in _node.get_children():
		_all_node_names.append(_child.name)
		if _child.get_child_count() > 0:
			var _result = get_all_node_names(_child)
			for _item in _result:
				_all_node_names.append(_item)
	return _all_node_names

func instantiate_current_item_at_position() -> void:
	if current_instance != null:
		populate_current_instance_rid_array(current_instance)
	var result = perform_raycast_with_exclusion(current_instance_rid_array)
	if result and result.collider:
		var instance = current_item.item.instantiate()
		scene_root.add_child(instance)
		instance.owner = scene_root
		initialize_node_name(instance, current_item.item_name)
		instance.global_transform.origin = result.position
		print("Instantiated: " + instance.name + " at " + str(instance.global_transform.origin))
	else:
		printerr("Failed to instantiate item, raycast missed")

func initialize_node_name(node : Node3D, new_name : String):
	var all_names = toolbox.get_all_node_names(scene_root)
	node.name = toolbox.increment_name_until_unique(new_name, all_names)

func perform_raycast_with_exclusion(exclude_rids: Array = []) -> Dictionary:
	var mouse_pos = viewport.get_mouse_position()
	var origin = camera.project_ray_origin(mouse_pos)
	var end = origin + camera.project_ray_normal(mouse_pos) * 1000
	var query = PhysicsRayQueryParameters3D.new()
	query.from = origin
	query.to = end
	query.exclude = exclude_rids
	return space.intersect_ray(query)

func populate_current_instance_rid_array(instance: Node):
	
	if instance is PhysicsBody3D:
		current_instance_rid_array.append(instance.get_rid())
	
	for child in instance.get_children():
		populate_current_instance_rid_array(child)

func refresh_collection_names():
	print("Refreshing collection names")
	
	var _names : CollectionNames = load(path_to_resource)
	if _names != null:
		var new_collection_names : Array[String] = []
		new_collection_names.append(_names.collection_name_01)
		new_collection_names.append(_names.collection_name_02)
		new_collection_names.append(_names.collection_name_03)
		new_collection_names.append(_names.collection_name_04)
		new_collection_names.append(_names.collection_name_05)
		new_collection_names.append(_names.collection_name_06)
		new_collection_names.append(_names.collection_name_07)
		new_collection_names.append(_names.collection_name_08)
		new_collection_names.append(_names.collection_name_09)
		new_collection_names.append(_names.collection_name_10)
		new_collection_names.append(_names.collection_name_11)
		new_collection_names.append(_names.collection_name_12)
		
		# Validate
		for _name in new_collection_names:
			if _name != "":
				var dir = DirAccess.open(path_root + _name)
				if dir:
					dir.list_dir_begin()
					var item = dir.get_next()
					if item != "":
						print("Collection directory is present and contains items: " + _name)
					else:
						printerr("Directory exists, but contains no items: " + _name)
				else:
					printerr("Collection directory does not exist: " + _name)
		collection_names = new_collection_names
	else:
		printerr("CollectioNames resource is null")
		collection_names = []
	
	#endregion
	
	var k : int = 0
	for tab_button : Button in btns_collection_tabs:
		k += 1
		tab_button = scene_builder_dock.get_node("Collection/Tab/%s" % k)
		var collection_name = collection_names[k-1]
		if collection_name == "":
			collection_name = " "
		tab_button.text = collection_name

func toggle_placement_mode() -> void:
	placement_mode_enabled = !placement_mode_enabled
	if not placement_mode_enabled:
		current_item = null
		current_item_name = ""
		clear_scene_builder_temp()

func update_temporary_item_position() -> void:
	if current_instance != null:
		populate_current_instance_rid_array(current_instance)
	var result = perform_raycast_with_exclusion(current_instance_rid_array)
	if result and result.collider:
		var temp_node = scene_root.get_node_or_null("SceneBuilderTemp")
		if temp_node and temp_node.get_child_count() > 0:
			var temp_instance = temp_node.get_child(0)
			temp_instance.global_transform.origin = result.position



