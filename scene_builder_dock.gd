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

# Indicators
var indicator_x : Label
var indicator_y : Label
var indicator_z : Label
var indicator_scale : Label

#endregion

# Updated by update_world_3d()
# Todo: This needs to be called on root scene change 
var editor : EditorInterface
var space : PhysicsDirectSpaceState3D
var world3d : World3D
var viewport : Viewport
var camera : Camera3D
var scene_root  # : Quack

# Updated when reloading all collections
var collection_names : Array[String] = []
var items_by_collection : Dictionary = {}
var item_highlighters_by_collection : Dictionary = {}
# Also updated on tab button click
var selected_collection : Dictionary = {}
var selected_collection_name : String = ""
# Also updated on item click
var selected_item : SceneBuilderItem = null
var selected_item_name : String = ""
var preview_instance : Node3D = null
var preview_instance_rid_array : Array[RID] = []

# Assorted variables
var placement_mode_enabled : bool = false
var rotation_mode_x_enabled : bool = false
var rotation_mode_y_enabled : bool = false
var rotation_mode_z_enabled : bool = false
var scale_mode_enabled : bool = false


var original_preview_basis : Basis = Basis.IDENTITY
var original_mouse_position : Vector2 = Vector2.ONE
var original_preview_scale : Vector3 = Vector3.ONE

var scene_builder_temp : Node

var rng : RandomNumberGenerator = RandomNumberGenerator.new()

# ---- Notifications -----------------------------------------------------------

func _enter_tree() -> void:
	
	#
	editor = get_editor_interface()
	toolbox = SceneBuilderToolbox.new()
	
	#
	update_world_3d()
	
	#region Initialize controls
	
	scene_builder_dock = load("res://addons/SceneBuilder/scene_builder_dock.tscn").instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, scene_builder_dock)
	
	# Tabs
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
		
	# Options
	btn_use_surface_normal = scene_builder_dock.get_node("Settings/Tab/Options/UseSurfaceNormal")
	btn_find_world_3d = scene_builder_dock.get_node("Settings/Tab/Options/Bottom/FindWorld3D")
	btn_reload_all_items = scene_builder_dock.get_node("Settings/Tab/Options/Bottom/ReloadAllItems")
	btn_find_world_3d.pressed.connect(update_world_3d)
	btn_reload_all_items.pressed.connect(reload_all_items)
	
	# Indicators
	indicator_x = scene_builder_dock.get_node("Settings/Indicators/1")
	indicator_y = scene_builder_dock.get_node("Settings/Indicators/2")
	indicator_z = scene_builder_dock.get_node("Settings/Indicators/3")
	indicator_scale = scene_builder_dock.get_node("Settings/Indicators/4")
	
	#endregion
	
	#
	refresh_collection_names()
	
	#
	reload_all_items()

func _exit_tree() -> void:
	remove_control_from_docks(scene_builder_dock)
	scene_builder_dock.queue_free()

func _process(delta: float) -> void:
	# Update preview item position
	if placement_mode_enabled:
		
		if !is_transform_mode_enabled():
			if preview_instance != null:
				populate_preview_instance_rid_array(preview_instance)
			var result = perform_raycast_with_exclusion(preview_instance_rid_array)
			if result and result.collider:
				var _preview_item = scene_root.get_node_or_null("SceneBuilderTemp")
				if _preview_item and _preview_item.get_child_count() > 0:
					var _instance = _preview_item.get_child(0)
					_instance.global_transform.origin = result.position
					
					if btn_use_surface_normal.button_pressed:
						_instance.global_transform.basis = align_up(_instance.global_transform.basis, result.normal)

func forward_3d_gui_input(_camera : Camera3D, event : InputEvent) -> AfterGUIInput:
	
	if event is InputEventMouseMotion:
		if placement_mode_enabled:
			var relative_motion : float
			if abs(event.relative.x) > abs(event.relative.y):
				relative_motion = event.relative.x
			else:
				relative_motion = -event.relative.y
			relative_motion *= 0.01  # Sensitivity
			
			if rotation_mode_x_enabled:
				preview_instance.rotate_x(relative_motion)
			elif rotation_mode_y_enabled:
				preview_instance.rotate_y(relative_motion)
			elif rotation_mode_z_enabled:
				preview_instance.rotate_z(relative_motion)
			elif scale_mode_enabled:
				var new_scale : Vector3 = preview_instance.scale * (1 + relative_motion)
				if is_zero_approx(new_scale.x) or is_zero_approx(new_scale.y) or is_zero_approx(new_scale.z):
					new_scale = original_preview_scale
				preview_instance.scale = new_scale
	
	if event is InputEventMouseButton and placement_mode_enabled:
		if event.is_pressed() and !event.is_echo():
			
			var mouse_pos = viewport.get_mouse_position()
			if mouse_pos.x >= 0 and mouse_pos.y >= 0: 
				if mouse_pos.x <= viewport.size.x and mouse_pos.y <= viewport.size.y:
					
					if event.button_index == MOUSE_BUTTON_LEFT:
						
						if is_transform_mode_enabled():
							# Confirm changes
							original_preview_basis = preview_instance.basis
							original_preview_scale = preview_instance.scale
							end_transform_mode()
							viewport.warp_mouse(original_mouse_position)
						else:
							instantiate_selected_item_at_position()
					
					if event.button_index == MOUSE_BUTTON_RIGHT:
					
						if is_transform_mode_enabled():
							# Revert preview transformations
							print("warping to: ", original_mouse_position)
							preview_instance.basis = original_preview_basis
							preview_instance.scale = original_preview_scale
							end_transform_mode()
							viewport.warp_mouse(original_mouse_position)
			
			else:
				printerr("Mouse position is out of bounds, not possible?")
		
		return EditorPlugin.AFTER_GUI_INPUT_STOP
		
	elif event is InputEventKey:
		if event.is_pressed() and !event.is_echo():
			
			if placement_mode_enabled:
				
				if event.alt_pressed:
					if event.keycode == KEY_Q:
						end_placement_mode()
				
				else:
					
					if event.keycode == KEY_1:
						if is_transform_mode_enabled():
							if rotation_mode_x_enabled:
								end_transform_mode()
							else:
								end_transform_mode()
								start_rotation_mode_x()
						else:
							start_rotation_mode_x()
					
					elif event.keycode == KEY_2:
						if is_transform_mode_enabled():
							if rotation_mode_y_enabled:
								end_transform_mode()
							else:
								end_transform_mode()
								start_rotation_mode_y()
						else:
							start_rotation_mode_y()
					
					elif event.keycode == KEY_3:
						if is_transform_mode_enabled():
							if rotation_mode_z_enabled:
								end_transform_mode()
							else:
								end_transform_mode()
								start_rotation_mode_z()
						else:
							start_rotation_mode_z()
					
					elif event.keycode == KEY_4:
						if is_transform_mode_enabled():
							if scale_mode_enabled:
								end_transform_mode()
							else:
								end_transform_mode()
								start_scale_mode()
						else:
							start_scale_mode()
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS

# ---- Buttons -----------------------------------------------------------------

func on_custom_tab_button_pressed(tab_index: int) -> void:
	
	end_placement_mode()
	
	tab_container.current_tab = tab_index-1
	selected_collection_name = collection_names[tab_index-1]
	
	if selected_collection_name == "" or selected_collection_name == " ":
		selected_collection = {}
	else:
		selected_collection = items_by_collection[selected_collection_name]

func on_item_icon_clicked(_button_name: String) -> void:
	
	var item_highlighters : Dictionary = item_highlighters_by_collection[selected_collection_name]
	
	var previously_selected_item_name = selected_item_name 
	if placement_mode_enabled:
		end_placement_mode()
	
	if previously_selected_item_name != _button_name:
		select_item(selected_collection_name, _button_name)

func reload_all_items() -> void:
	
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

func update_world_3d() -> void:
	scene_root = editor.get_edited_scene_root()
	if not scene_root or not scene_root is Node3D:
		printerr("Scene root is not of type Node3D")
		return
	
	viewport = editor.get_editor_viewport_3d()
	world3d = viewport.find_world_3d()
	space = world3d.direct_space_state
	camera = viewport.get_camera_3d()
	
	if scene_root == null:
		printerr("scene_root not found")

# ---- Helpers -----------------------------------------------------------------

func align_up(node_basis, normal) -> Basis:
	var result : Basis = Basis()
	var scale : Vector3 = node_basis.get_scale()

	# Choose an arbitrary vector that is not parallel to the normal.
	# This helps in avoiding degenerate cross products.
	var arbitrary_vector : Vector3 = Vector3(1, 0, 0) if abs(normal.dot(Vector3(1, 0, 0))) < 0.999 else Vector3(0, 1, 0)

	# Calculate the cross product of the normal and the node's Z axis.
	# If the result is nearly zero (indicating parallelism), use the arbitrary vector instead.
	var crossX = normal.cross(node_basis.z).normalized()
	if crossX.length_squared() < 0.001:
		crossX = normal.cross(arbitrary_vector).normalized()

	var crossZ = crossX.cross(normal).normalized()

	result.x = crossX
	result.y = normal
	result.z = crossZ

	result = result.orthonormalized()
	result.x *= scale.x
	result.y *= scale.y
	result.z *= scale.z

	return result

func clear_preview_instance() -> void:
	
	if scene_root == null:
		printerr("scene_root is null inside clear_preview_item")
		return
	
	preview_instance = null
	preview_instance_rid_array = []
	
	var temp_node = scene_root.get_node_or_null("SceneBuilderTemp")
	if temp_node:
		for child in temp_node.get_children():
			child.queue_free()

func create_preview_instance() -> void:
	
	if scene_root == null:
		printerr("scene_root is null inside create_preview_item_instance")
		return
	
	clear_preview_instance() 
	
	scene_builder_temp = scene_root.get_node_or_null("SceneBuilderTemp")
	if not scene_builder_temp:
		scene_builder_temp = Node.new()
		scene_builder_temp.name = "SceneBuilderTemp"
		scene_root.add_child(scene_builder_temp)
		scene_builder_temp.owner = scene_root
	
	preview_instance = selected_item.item.instantiate()
	scene_builder_temp.add_child(preview_instance)
	preview_instance.owner = scene_root
	
	var x_scale : float = rng.randf_range(selected_item.random_scale_x_min, selected_item.random_scale_x_max)
	var y_scale : float = rng.randf_range(selected_item.random_scale_y_min, selected_item.random_scale_y_max)
	var z_scale : float = rng.randf_range(selected_item.random_scale_z_min, selected_item.random_scale_z_max)
	original_preview_scale = Vector3(x_scale, y_scale, z_scale)
	preview_instance.scale = original_preview_scale
	
	var x_rot : float = rng.randf_range(0, selected_item.random_rot_x)
	var y_rot : float = rng.randf_range(0, selected_item.random_rot_y)
	var z_rot : float = rng.randf_range(0, selected_item.random_rot_z)
	
	preview_instance.rotation = Vector3(deg_to_rad(x_rot), deg_to_rad(y_rot), deg_to_rad(z_rot))
	original_preview_basis = preview_instance.basis
	
	# Instantiating a node automatically selects it, which is annoying.
	# Let's re-select scene_root instead,
	editor.get_selection().clear()
	editor.get_selection().add_node(scene_root)

func end_transform_mode() -> void:
	rotation_mode_x_enabled = false
	rotation_mode_y_enabled = false
	rotation_mode_z_enabled = false
	scale_mode_enabled = false
	indicator_x.self_modulate = Color.WHITE
	indicator_y.self_modulate = Color.WHITE
	indicator_z.self_modulate = Color.WHITE
	indicator_scale.self_modulate = Color.WHITE

func end_placement_mode() -> void:
	
	clear_preview_instance()
	end_transform_mode()
	
	placement_mode_enabled = false
	
	if selected_item_name != "":
		if item_highlighters_by_collection.has(selected_collection_name):
			var item_highlighters : Dictionary = item_highlighters_by_collection[selected_collection_name]
			if item_highlighters.has(selected_item_name):
				var selected_nine_path : NinePatchRect = item_highlighters[selected_item_name]
				if selected_nine_path:
					selected_nine_path.self_modulate = Color.BLACK
				else:
					print("NinePatchRect is null for selected_item_name: ", selected_item_name)
			else:
				print("Key missing from highlighter collection, key: ", selected_item_name, ", from collection: ", selected_collection_name)
		else:
			print("Highlighter collection missing for collection: ", selected_collection_name)

	selected_item = null
	selected_item_name = ""

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

func get_all_node_names(_node) -> Array[String]:
	var _all_node_names = []
	for _child in _node.get_children():
		_all_node_names.append(_child.name)
		if _child.get_child_count() > 0:
			var _result = get_all_node_names(_child)
			for _item in _result:
				_all_node_names.append(_item)
	return _all_node_names

func instantiate_selected_item_at_position() -> void:
	
	if preview_instance != null:
		populate_preview_instance_rid_array(preview_instance)
	
	var result = perform_raycast_with_exclusion(preview_instance_rid_array)
	
	if result and result.collider:
		
		var instance = selected_item.item.instantiate()
		scene_root.add_child(instance)
		instance.owner = scene_root
		initialize_node_name(instance, selected_item.item_name)
		
		instance.global_transform.origin = result.position
		instance.basis = preview_instance.basis
		
		print("Instantiated: " + instance.name + " at " + str(instance.global_transform.origin))
	
	else:
		printerr("Failed to instantiate item, raycast missed")

func initialize_node_name(node : Node3D, new_name : String) -> void:
	var all_names = toolbox.get_all_node_names(scene_root)
	node.name = toolbox.increment_name_until_unique(new_name, all_names)

func is_transform_mode_enabled() -> bool:
	if rotation_mode_x_enabled or rotation_mode_y_enabled or rotation_mode_z_enabled or scale_mode_enabled:
		return true;
	else: 
		return false

func perform_raycast_with_exclusion(exclude_rids: Array = []) -> Dictionary:
	var mouse_pos = viewport.get_mouse_position()
	var origin = camera.project_ray_origin(mouse_pos)
	var end = origin + camera.project_ray_normal(mouse_pos) * 1000
	var query = PhysicsRayQueryParameters3D.new()
	query.from = origin
	query.to = end
	query.exclude = exclude_rids
	return space.intersect_ray(query)

func populate_preview_instance_rid_array(instance: Node) -> void:
	
	if instance is PhysicsBody3D:
		preview_instance_rid_array.append(instance.get_rid())
	
	for child in instance.get_children():
		populate_preview_instance_rid_array(child)

func refresh_collection_names() -> void:
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

func select_item(collection_name : String, item_name : String) -> void:
	end_placement_mode()
	var nine_path : NinePatchRect = item_highlighters_by_collection[collection_name][item_name]
	nine_path.self_modulate = Color.GREEN
	selected_item_name = item_name
	selected_item = selected_collection[selected_item_name]
	create_preview_instance()
	placement_mode_enabled = true;

func start_rotation_mode_x() -> void:
	original_mouse_position = viewport.get_mouse_position()
	original_preview_basis = preview_instance.basis
	rotation_mode_x_enabled = true
	indicator_x.self_modulate = Color.GREEN

func start_rotation_mode_y() -> void:
	original_mouse_position = viewport.get_mouse_position()
	original_preview_basis = preview_instance.basis
	rotation_mode_y_enabled = true
	indicator_y.self_modulate = Color.GREEN

func start_rotation_mode_z() -> void:
	original_mouse_position = viewport.get_mouse_position()
	original_preview_basis = preview_instance.basis
	rotation_mode_z_enabled = true
	indicator_z.self_modulate = Color.GREEN

func start_scale_mode() -> void:
	original_mouse_position = viewport.get_mouse_position()
	original_preview_scale = preview_instance.scale
	scale_mode_enabled = true
	indicator_scale.self_modulate = Color.GREEN








