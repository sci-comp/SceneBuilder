extends Node

static func replace_first(s: String, pattern: String, replacement: String) -> String:
	var index = s.find(pattern)
	if index == -1:
		return s
	return s.substr(0, index) + replacement + s.substr(index + pattern.length())

static func replace_last(s: String, pattern: String, replacement: String) -> String:
	var index = s.rfind(pattern)
	if index == -1:
		return s
	return s.substr(0, index) + replacement + s.substr(index + pattern.length())

static func get_unique_name(base_name: String, parent: Node) -> String:
	var new_name = "temporary_name"
	#var ends_with_digit = base_name.match(".*\\d+$")
	
	var ends_with_digit: bool = false
	if (base_name.length() > 0 and base_name[-1].is_valid_int()):
		ends_with_digit = true
	
	var regex = RegEx.new()
	regex.compile("^(.*?)(\\d+)$")
	
	print("Searching for a unique name...")
	
	if (parent.has_node(base_name)):
		new_name = base_name
		while parent.has_node(new_name):
			print("Existing name has been taken: " + new_name)
			if ends_with_digit:
				var result = regex.search(new_name)
				if result:
					var name_part = result.get_string(1)
					var num_part = int(result.get_string(2))
					new_name = name_part + str(num_part + 1)
				else:
					new_name = base_name + str(1)
			else:
				new_name = base_name + str(1)
	else:
		print("Existing name may be used as is.")
		new_name = base_name
	
	print("Returning: " + new_name)
	
	return new_name
