@tool
extends EditorPlugin

# Editor
var editor : EditorInterface
var space : PhysicsDirectSpaceState3D 
var world3d : World3D
var viewport : Viewport
var camera : Camera3D
var scene_root

# UI
var scene_builder_dock : VBoxContainer
var path_root : String = "res://Data/SceneBuilder/"
var path_to_tmp_icon : String = "res://addons/SceneBuilder/icon_tmp.png"
var icon_grid : GridContainer

var scene_collection : SceneBuilderCollection

func _enter_tree():
	
	editor = get_editor_interface()	
	update_world_3d()
	
	scene_builder_dock = load("res://addons/SceneBuilder/scene_builder_dock.tscn").instantiate()
	
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, scene_builder_dock)
	icon_grid = scene_builder_dock.get_node("Icons/Grid")
	scene_collection = load(path_root + "scene_collection_01.tres")
	
	populate_icon_grid()

func _exit_tree():
	remove_control_from_docks(scene_builder_dock)
	scene_builder_dock.queue_free()

func update_world_3d():
	scene_root = editor.get_edited_scene_root()
	viewport = editor.get_editor_viewport_3d()
	world3d = viewport.find_world_3d()
	space = world3d.direct_space_state
	camera = viewport.get_camera_3d()

func populate_icon_grid():
	
	var valid_paths = get_validated_scene_paths(scene_collection.scene_paths)
	
	for path in valid_paths:
		var texture_button : TextureButton = TextureButton.new()
		texture_button.texture_normal = load(path_to_tmp_icon)
		icon_grid.add_child(texture_button)

func get_validated_scene_paths(scene_paths : Array) -> Array:
	var valid_paths = []
	for path in scene_paths:
		if path.ends_with(".tscn") or path.ends_with(".glb"):
			valid_paths.append(path)
		else:
			printerr("Invalid path: ", path, ". Only .tscn and .glb files are supported.")
	return valid_paths

func instantiate_at_cursor(path):
	var mouse_pos = viewport.get_mouse_position()
	
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is PackedScene:
			var scene : PackedScene = loaded
	
			var parent_node = scene_root
			
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
			
			parent_node.add_child(instance)
			instance.owner = scene_root
			instance.global_transform = transform
			
			print("Instantiated: " + instance.name + " at " + str(instance.global_transform.origin))



