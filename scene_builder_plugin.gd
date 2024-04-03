@tool
extends EditorPlugin

var scene_builder_dock = load("res://addons/SceneBuilder/scene_builder_dock.gd").new()
var scene_builder_commands = load("res://addons/SceneBuilder/scene_builder_commands.gd").new()

func _enter_tree():	
	add_child(scene_builder_commands)
	add_child(scene_builder_dock)

func _exit_tree():
	scene_builder_commands.queue_free()
	scene_builder_dock.queue_free()

func _handles(object):
	return object is Node3D

func _forward_3d_gui_input(camera : Camera3D, event : InputEvent):
	scene_builder_dock.forward_3d_gui_input(camera, event)


