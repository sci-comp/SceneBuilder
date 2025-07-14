@tool
extends EditorPlugin

func execute():
	var selection: EditorSelection = EditorInterface.get_selection()
	var selected_nodes: Array[Node] = selection.get_selected_nodes()
	var selected_paths: PackedStringArray = EditorInterface.get_selected_paths()

	if selected_nodes.size() != 1:
		print("[Add Audio Randomizer] Exactly one AudioStreamPlayer must be selected.")
		return

	var audio_player = selected_nodes[0]
	if not audio_player is AudioStreamPlayer:
		print("[Add Audio Randomizer] Selected node must be an AudioStreamPlayer.")
		return

	if selected_paths.is_empty():
		print("[Add Audio Randomizer] At least one audio file must be selected in FileSystem.")
		return

	var audio_extensions = [".wav", ".ogg"]
	var valid_streams = []
	
	for path in selected_paths:
		var extension = "." + path.get_extension()
		if extension in audio_extensions:
			var audio_stream = load(path)
			if audio_stream:
				valid_streams.append(audio_stream)
				print("[Add Audio Randomizer] Loaded: " + path.get_file())

	if valid_streams.is_empty():
		print("[Add Audio Randomizer] No valid audio files found.")
		return

	var randomizer: AudioStreamRandomizer

	if audio_player.stream and audio_player.stream is AudioStreamRandomizer:
		randomizer = audio_player.stream
		print("[Add Audio Randomizer] Using existing AudioStreamRandomizer")
	else:
		randomizer = AudioStreamRandomizer.new()
		if audio_player.stream:
			randomizer.add_stream(0, audio_player.stream, 1.0)
		audio_player.stream = randomizer
		print("[Add Audio Randomizer] Created new AudioStreamRandomizer")

	for stream in valid_streams:
		randomizer.add_stream(randomizer.streams_count, stream, 1.0)

	print("[Add Audio Randomizer] Added " + str(valid_streams.size()) + " streams to randomizer")
