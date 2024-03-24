extends Node

var collection_01 : Button = $"Tab/1"
var collection_02 : Button = $"Tab/2"
var collection_03 : Button = $"Tab/3"
var collection_04 : Button = $"Tab/4"
var collection_05 : Button = $"Tab/5"
var collection_06 : Button = $"Tab/6"
var collection_07 : Button = $"Tab/7"
var collection_08 : Button = $"Tab/8"
var collection_09 : Button = $"Tab/9"
var collection_10 : Button = $"Tab/10"
var collection_11 : Button = $"Tab/11"
var collection_12 : Button = $"Tab/12"

var tab_container : TabContainer = $"TabContainer"

func _ready():
	collection_01.pressed.connect(on_button_pressed(1))
	collection_02.pressed.connect(on_button_pressed(2))
	collection_03.pressed.connect(on_button_pressed(3))
	collection_04.pressed.connect(on_button_pressed(4))
	collection_05.pressed.connect(on_button_pressed(5))
	collection_06.pressed.connect(on_button_pressed(6))
	collection_07.pressed.connect(on_button_pressed(7))
	collection_08.pressed.connect(on_button_pressed(8))
	collection_09.pressed.connect(on_button_pressed(9))
	collection_10.pressed.connect(on_button_pressed(10))
	collection_11.pressed.connect(on_button_pressed(11))
	collection_12.pressed.connect(on_button_pressed(12))

func on_button_pressed(tab_index: int):
	tab_container.current_tab = tab_index
