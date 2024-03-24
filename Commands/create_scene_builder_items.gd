@tool
extends EditorPlugin

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
		#var scene = load(file_path) as PackedScene
		
		resource.scene_path = path
		resource.item_name = path.get_file().get_basename()
		resource.collection = collection_line_edit.text
		
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
		
		var save_path = "res://Data/SceneBuilder/Collection/%s/%s.tres" % [resource.collection, resource.item_name]
		
		var dir = DirAccess.open(save_path)
		if not dir:
			dir.make_dir(save_path)

		ResourceSaver.save(resource, save_path)
		
		print("Resource created: " + resource.item_name)





