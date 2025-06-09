@tool
extends EditorPlugin
## Creates Scene Builder items from selection on Editor.
## A Popup is created in which user can change creation settings.

var path_root = "res://Data/SceneBuilderCollections/"

var editor: EditorInterface
var popup_instance: PopupPanel

# Nodes
var create_items: VBoxContainer
var collection_line_edit: LineEdit
var randomize_vertical_offset_checkbox: CheckButton
var randomize_rotation_checkbox: CheckButton
var randomize_scale_checkbox: CheckButton
var vertical_offset_spin_box_min: SpinBox
var vertical_offset_spin_box_max: SpinBox
var rotx_slider: HSlider
var roty_slider: HSlider
var rotz_slider: HSlider
var scale_spin_box_min: SpinBox
var scale_spin_box_max: SpinBox
var ok_button: Button

var max_diameter: float
var icon_studio: SubViewport

signal done

func execute(root_dir: String):
	if !root_dir.is_empty():
		path_root = root_dir

	print("[Create Scene Builder Items] Requesting user input...")

	editor = get_editor_interface()

	popup_instance = PopupPanel.new()
	add_child(popup_instance)
	popup_instance.popup_centered(Vector2(500, 300))

	var create_items_scene_path = SceneBuilderToolbox.find_resource_with_dynamic_path("scene_builder_create_items.tscn")
	if create_items_scene_path == "":
		printerr("[Create Scene Builder Items] Could not find scene_builder_create_items.tscn")
		return

	var create_items_scene := load(create_items_scene_path)
	create_items = create_items_scene.instantiate()
	popup_instance.add_child(create_items)

	collection_line_edit = create_items.get_node("Collection/LineEdit")
	randomize_vertical_offset_checkbox = create_items.get_node("Boolean/VerticalOffset")
	randomize_rotation_checkbox = create_items.get_node("Boolean/Rotation")
	randomize_scale_checkbox = create_items.get_node("Boolean/Scale")
	vertical_offset_spin_box_min = create_items.get_node("VerticalOffset/min")
	vertical_offset_spin_box_max = create_items.get_node("VerticalOffset/max")
	rotx_slider = create_items.get_node("Rotation/x")
	roty_slider = create_items.get_node("Rotation/y")
	rotz_slider = create_items.get_node("Rotation/z")
	scale_spin_box_min = create_items.get_node("Scale/min")
	scale_spin_box_max = create_items.get_node("Scale/max")
	ok_button = create_items.get_node("Okay")

	ok_button.pressed.connect(_on_ok_pressed)

func _on_ok_pressed():
	print("[Create Scene Builder Items] On okay pressed")

	var path_to_icon_studio : String = SceneBuilderToolbox.find_resource_with_dynamic_path("icon_studio.tscn")
	
	if path_to_icon_studio == "":
		printerr("[Create Scene Builder Items] Path to icon studio not found")
		return

	EditorInterface.open_scene_from_path(path_to_icon_studio)

	icon_studio = EditorInterface.get_edited_scene_root() as SubViewport
	if icon_studio == null:
		print("[Create Scene Builder Items] Failed to load icon studio")
		return

	var selected_paths = EditorInterface.get_selected_paths()
	print("[Create Scene Builder Items] Selected paths: " + str(selected_paths.size()))

	for path in selected_paths:
		await _create_resource(path)

	popup_instance.queue_free()
	done.emit()

func _create_resource(path: String):
	var scene_builder_item_path: String
	var scene_builder_item_path1: String = "res://addons/SceneBuilder/scene_builder_item.gd"
	var scene_builder_item_path2: String = "res://addons/SceneBuilder/addons/SceneBuilder/scene_builder_item.gd"

	if FileAccess.file_exists(scene_builder_item_path1):
		scene_builder_item_path = scene_builder_item_path1
	elif FileAccess.file_exists(scene_builder_item_path2):
		scene_builder_item_path = scene_builder_item_path2
	else:
		print("[Create Scene Builder Items] Path to scene builder item not found")
		return

	var resource: SceneBuilderItem = load(scene_builder_item_path).new()

	if ResourceLoader.exists(path):
		var packed_scene: PackedScene = load(path)

		if packed_scene == null:
			return

		# Populate resource
		var uid = ResourceUID.id_to_text(ResourceLoader.get_resource_uid(path))
		resource.uid = uid
		resource.item_name = path.get_file().get_basename()
		if collection_line_edit.text.is_empty():
			print("[Create Scene Builder Items] Collection name was not given, using: Unnamed")
			resource.collection_name = "Unnamed"
		else:
			resource.collection_name = collection_line_edit.text
		resource.use_random_vertical_offset = randomize_vertical_offset_checkbox.button_pressed
		resource.use_random_rotation = randomize_rotation_checkbox.button_pressed
		resource.use_random_scale = randomize_scale_checkbox.button_pressed
		resource.random_offset_y_min = vertical_offset_spin_box_min.value
		resource.random_offset_y_max = vertical_offset_spin_box_max.value
		resource.random_rot_x = rotx_slider.value
		resource.random_rot_y = roty_slider.value
		resource.random_rot_z = rotz_slider.value
		resource.random_scale_min = scale_spin_box_min.value
		resource.random_scale_min = scale_spin_box_min.value

		# Create directories
		var path_to_collection_folder = path_root + resource.collection_name
		_create_directory_if_not_exists(path_to_collection_folder)

		#region Create icon

		# Add packed_scene to studio scene
		var subject: Node3D = packed_scene.instantiate()
		icon_studio.add_child(subject)
		subject.owner = icon_studio
		
		var camera_root: Node3D = icon_studio.get_node("CameraRoot") as Node3D
		var studio_camera: Camera3D = icon_studio.get_node("CameraRoot/Pitch/Camera3D") as Camera3D

		# Center item in portrait frame
		# Defaulting to 5 node child layers to get AABB
		# Possible improvement : add parameter to UI
		var node_depth = 5
		var aabb = await _get_merged_aabb(subject, node_depth)
		print("[Create Scene Builder Items] Subject AABB: ", aabb)
		var center = aabb.get_center()
		print("[Create Scene Builder Items] Subject center: ", center)
		camera_root.position = center
		# Using 120% of longest axis for cases where the subject gets too close to camera
		studio_camera.position = Vector3(0, 0, aabb.get_longest_axis_size() * 1.2)

		await get_tree().process_frame
		await get_tree().process_frame

		var viewport_tex: Texture = icon_studio.get_texture()
		var img: Image = viewport_tex.get_image()
		var tex: Texture = ImageTexture.create_from_image(img)

		resource.texture = tex

		await get_tree().process_frame
		subject.queue_free()

		#endregion

		var save_path: String = path_root + resource.collection_name + "/%s.tres" % resource.item_name
		ResourceSaver.save(resource, save_path)

		print("[Create Scene Builder Items] Resource saved: " + save_path)

func _create_directory_if_not_exists(path_to_directory: String) -> void:
	var dir = DirAccess.open(path_to_directory)
	if not dir:
		print("[Create Scene Builder Items] Creating directory: " + path_to_directory)
		DirAccess.make_dir_recursive_absolute(path_to_directory)

# Returns the merged AABB of node and it's children up to node_depth layers
func _get_merged_aabb(node: Node, node_depth: int) -> AABB:
	var aabb := AABB()
	
	if node is GeometryInstance3D:
		if node is CSGShape3D:
			await _wait_for_csg_update()
		aabb = node.global_transform * node.get_aabb()
	
	if node_depth > 0:
		for child in node.get_children():
			var child_aabb = await _get_merged_aabb(child, node_depth - 1)
			aabb = aabb.merge(child_aabb)
	
	return aabb

# CSGShape3D does not update its AABB immediately
# This behavior is intentional and documented here:
# https://github.com/godotengine/godot/issues/38273
func _wait_for_csg_update():
	await get_tree().process_frame
	await get_tree().process_frame
