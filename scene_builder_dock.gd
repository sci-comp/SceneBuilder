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
var collection_tabs : TabContainer
var path_root : String = "res://Data/SceneBuilder/"
var path_to_tmp_icon : String = "res://addons/SceneBuilder/icon_tmp.png"

# Collections
var scene_collection : Array
var collection_names : Array

func _enter_tree():
	
	editor = get_editor_interface()
	update_world_3d()
	
	scene_builder_dock = load("res://addons/SceneBuilder/scene_builder_dock.tscn").instantiate()
	
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, scene_builder_dock)
	
	# For each collection in collections
	# Add a tab group > Add a scroll container > Add a grid container
	# Populate icon grid
	
	var root_path = "res://Data/SceneBuilderCollections/"
	
	for i in range(1, 13):
		var line_edit : LineEdit = get_node("Settings/Collections/VBox/HBox/Left/%s/Name" % i)
		collection_names.append(line_edit.text)
		
		
		
		var dir = DirAccess.open()
		if not dir:
			dir.make_dir(save_path)
		
		populate_icon_grid()

func populate_icon_grid():
	print("tmp")
	'''var valid_paths = get_validated_scene_paths(scene_collection.scene_paths)
	
	for path in valid_paths:
		var texture_button : TextureButton = TextureButton.new()
		texture_button.texture_normal = load(path_to_tmp_icon)
		icon_grid.add_child(texture_button)'''

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

func _exit_tree():
	remove_control_from_docks(scene_builder_dock)
	scene_builder_dock.queue_free()

func update_world_3d():
	scene_root = editor.get_edited_scene_root()
	viewport = editor.get_editor_viewport_3d()
	world3d = viewport.find_world_3d()
	space = world3d.direct_space_state
	camera = viewport.get_camera_3d()

