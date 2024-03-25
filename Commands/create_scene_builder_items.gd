@tool
extends EditorPlugin

var path_root = "res://Data/SceneBuilderCollections/"

var editor : EditorInterface
var popup_instance: PopupPanel

# Nodes
var create_items : VBoxContainer

var collection_line_edit : LineEdit

var randomize_rotation_checkbox : CheckButton
var randomize_scale_checkbox : CheckButton

var rotx_slider : HSlider
var roty_slider : HSlider
var rotz_slider : HSlider

var scalex_spin_box_min : SpinBox
var scalex_spin_box_max : SpinBox
var scaley_spin_box_min : SpinBox
var scaley_spin_box_max : SpinBox
var scalez_spin_box_min : SpinBox
var scalez_spin_box_max : SpinBox

var ok_button: Button

signal done

func execute():
	
	print("Requesting user input...")
	
	editor = get_editor_interface()
	
	popup_instance = PopupPanel.new()
	add_child(popup_instance)
	popup_instance.popup_centered(Vector2(500, 300))
	
	create_items = load("res://addons/SceneBuilder/scene_builder_create_items.tscn").instantiate()
	popup_instance.add_child(create_items)
	
	collection_line_edit = create_items.get_node("Collection/LineEdit")
	randomize_rotation_checkbox = create_items.get_node("Boolean/Rotation")
	randomize_scale_checkbox = create_items.get_node("Boolean/Scale")
	rotx_slider = create_items.get_node("Rotation/x")
	roty_slider = create_items.get_node("Rotation/y")
	rotz_slider = create_items.get_node("Rotation/z")
	scalex_spin_box_min = create_items.get_node("ScaleMin/x")
	scalex_spin_box_max = create_items.get_node("ScaleMax/x")
	scaley_spin_box_min = create_items.get_node("ScaleMin/y")
	scaley_spin_box_max = create_items.get_node("ScaleMax/y")
	scalez_spin_box_min = create_items.get_node("ScaleMin/z")
	scalez_spin_box_max = create_items.get_node("ScaleMax/z")
	ok_button = create_items.get_node("Okay")
	
	ok_button.pressed.connect(_on_ok_pressed)

func _on_ok_pressed():
	
	print("User input has been set")
	
	var selected_paths = editor.get_selected_paths()
	
	print("Selected paths: " + str(selected_paths.size()))
	for path in selected_paths:
		_create_resource(path)
	
	popup_instance.queue_free()
	emit_signal("done")

func _create_resource(path: String):
	
	var resource : SceneBuilderItem = load("res://addons/SceneBuilder/scene_builder_item.gd").new()
	
	if ResourceLoader.exists(path) and load(path) is PackedScene:
		
		resource.scene_path = path
		resource.item_name = path.get_file().get_basename()
		resource.collection_name = collection_line_edit.text
		
		# icon
		resource.icon = load("res://addons/SceneBuilder/icon_tmp.png")
		
		resource.use_random_rotation = randomize_rotation_checkbox.button_pressed
		resource.use_random_scale = randomize_scale_checkbox.button_pressed
		
		resource.random_rot_x = rotx_slider.value
		resource.random_rot_y = roty_slider.value
		resource.random_rot_z = rotz_slider.value
		
		resource.random_scale_x_min = scalex_spin_box_min.value
		resource.random_scale_y_min = scaley_spin_box_min.value
		resource.random_scale_z_min = scalez_spin_box_min.value
		resource.random_scale_x_max = scalex_spin_box_max.value
		resource.random_scale_y_max = scaley_spin_box_max.value
		resource.random_scale_z_max = scalez_spin_box_max.value
		
		var path_to_collection_folder = path_root + resource.collection_name
		var path_to_item_folder = path_to_collection_folder + "/Item"
		var path_to_thumbnail_folder = path_to_collection_folder + "/Thumbnail"
		
		create_directory_if_not_exists(path_to_collection_folder)
		create_directory_if_not_exists(path_to_item_folder)
		create_directory_if_not_exists(path_to_thumbnail_folder)

		create_icon(resource.scene_path, resource.collection_name)
		
		var save_path = path_to_item_folder + "/%s.tres" % resource.item_name
		ResourceSaver.save(resource, save_path)
		print("Resource saved: " + save_path)

func create_directory_if_not_exists(path_to_directory: String) -> void:
	var dir = DirAccess.open(path_to_directory)
	if not dir:
		print("Creating directory: " + path_to_directory)
		dir.make_dir_recursive(path_to_directory)
		
func create_icon(scene_path : String, collection_name : String) -> void:
	# Validate the path and load the scene.
	if not scene_path.ends_with(".glb") and not scene_path.ends_with(".tscn"):
		print("Invalid scene file. Must end with .glb or .tscn")
		return
	var packed_scene = load(scene_path) as PackedScene
	if packed_scene == null:
		print("Failed to load the scene.")
		return
	var object_name = scene_path.get_file().get_basename()
	
	# Instantiate icon_studio.tscn
	var icon_studio_scene = load("res://addons/SceneBuilder/icon_studio.tscn") as PackedScene
	if icon_studio_scene == null:
		print("Failed to load icon studio.")
		return
	var studio_instance : SubViewport = icon_studio_scene.instantiate()
	var studio_camera : Camera3D = studio_instance.get_node("CameraRoot/Pitch/Camera3D") as Camera3D
	if studio_camera == null:
		print("Camera3D not found in icon studio.")
		return
	
	# Add subject to studio scene
	var scene_instance : Node3D = packed_scene.instantiate()
	studio_instance.add_child(scene_instance)
	
	#await get_tree().create_timer(1)
	#await RenderingServer.frame_post_draw
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Bug! https://github.com/godotengine/godot/issues/81754
	# Todo: Fix after bug is patched
	var img = studio_instance.get_texture().get_image()
	var save_path = path_root + "%s/Thumbnail/%s.png" % [collection_name, object_name]
	print("Saving icon to: ", save_path)
	img.save_png(save_path)



