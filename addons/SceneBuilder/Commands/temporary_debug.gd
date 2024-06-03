@tool
extends EditorPlugin

func execute():
	var editor = get_editor_interface()
	var base = editor.get_base_control()
	
	var use_local_space : Button = base.get_node("/root/@EditorNode@17172/@Panel@13/@VBoxContainer@14/@HSplitContainer@17/@HSplitContainer@25/@HSplitContainer@33/@VBoxContainer@34/@VSplitContainer@36/@VSplitContainer@62/@VBoxContainer@63/@PanelContainer@110/MainScreen/@Node3DEditor@10010/@MarginContainer@9465/@HFlowContainer@9466/@HBoxContainer@9467/@Button@9480")
	
	print("use_local_space.button_pressed: ", use_local_space.button_pressed)
	
