@tool
extends EditorPlugin

func execute():
	
	var editor_selection : EditorSelection = EditorInterface.get_selection()
	var selected_nodes : Array = editor_selection.get_selected_nodes()
	var selected_paths : PackedStringArray = EditorInterface.get_selected_paths()

	var current_scene : Node = EditorInterface.get_edited_scene_root()
	if current_scene == null or selected_paths.is_empty():
		print("Something is null or empty, returning early")
		return

	var audio_extensions = [".wav", ".ogg", ".mp3"]

	if selected_nodes.size() == 1:
		var node = selected_nodes[0]

		if selected_paths.size() > 0:
			print("Creating " + str(selected_paths.size()) + " audio sources for: " + node.name)

			for path in selected_paths:
				var extension = "." + path.get_extension()
				if extension in audio_extensions:
					var audio_player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()

					audio_player.name = path.get_file().get_basename()
					audio_player.stream = load(path)

					node.add_child(audio_player)
					audio_player.owner = current_scene

					print("Assigned: " + path.get_file())

				else:
					print("Selected path is not a wav file: " + str(path))
		else:
			print("Select a sound group in the scene.")
	else:
		print("Only one node in the scene should be selected.")
