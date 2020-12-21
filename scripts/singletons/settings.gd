extends Node

const DEBUG_MODE : bool = true

func _ready():
	pass # Replace with function body.
	
func is_debug_mode():
	return self.DEBUG_MODE
	
func get_root_folder():
	if is_debug_mode():
		return "res://"
	else:
		return OS.get_executable_path().get_base_dir()

func ensure_dir(path):
	var dir = Directory.new()
	if not dir.dir_exists(path):
		dir.make_dir(path)
	return path
