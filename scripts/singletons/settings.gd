extends Node

const DEBUG_MODE : bool = true
const DEBUG_ROOT_FOLDER : bool = false

func is_debug_mode():
	return self.DEBUG_MODE
	
func get_root_folder():
	if DEBUG_ROOT_FOLDER:
		return "res://"
	else:
		return OS.get_executable_path().get_base_dir()

func ensure_dir(path):
	var dir = Directory.new()
	if not dir.dir_exists(path):
		dir.make_dir(path)
	return path
