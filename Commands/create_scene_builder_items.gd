@tool
extends EditorPlugin

var editor : EditorInterface

var popup_instance: PopupPanel

# Nodes
var create_items : VBoxContainer

var randomize_rotation_checkbox : CheckBox
var randomize_scale_checkbox : CheckBox

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
	
	editor = get_editor_interface()
	
	popup_instance = PopupPanel.new()
	add_child(popup_instance)
	popup_instance.popup_centered(Vector2(500, 300))
	
	create_items = load("res://addons/SceneBuilder/Commands/create_scene_builder_items.gd").instantiate()
	popup_instance.add_child(create_items)
	
	randomize_rotation_checkbox = $Boolean/Rotation
	randomize_scale_checkbox = $Boolean/Scale
	rotx_slider = $Rotation/x
	roty_slider = $Rotation/y
	rotz_slider = $Rotation/z
	scalex_spin_box_min = $ScaleMin/x
	scalex_spin_box_max = $ScaleMax/x
	scaley_spin_box_min = $ScaleMin/y
	scaley_spin_box_max = $ScaleMax/y
	scalez_spin_box_min = $ScaleMin/z
	scalez_spin_box_max = $ScaleMax/z
	
	# Ok Button
	ok_button = $Okay
	ok_button.pressed.connect(_on_ok_pressed)

func _on_ok_pressed():
	
	var selected_paths = editor.get_selected_paths()
		
	for path in selected_paths:
		_create_resource(path)
	
	popup_instance.queue_free()
	emit_signal("done")

func _create_resource(path: String):
	
	var resource = load("res://addons/SceneBuilder/scene_builder_item.gd").new()
	
	if ResourceLoader.exists(path) and load(path) is PackedScene:
		#var scene = load(file_path) as PackedScene
		
		resource.scene_path = path
		resource.item_name = path.get_basename()
		resource.desired_rotation = _parse_vector3(desired_rotation_edit.text)
		resource.desired_scale = _parse_vector3(desired_scale_edit.text)
		var save_path = "res://path_to_save_resources/%s.tres" % resource.item_name
		ResourceSaver.save(save_path, resource)

func _parse_vector3(vector_string: String) -> Vector3:
	
	var parts = vector_string.split(",")
	if parts.size() != 3:
		return Vector3()
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))






