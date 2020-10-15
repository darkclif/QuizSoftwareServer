extends VBoxContainer

func _ready():
	# Print prompt
	self.add_line("Console started!")

func get_time_string():
	var timeDict = OS.get_time();
	return "[%02d:%02d:%02d] " % [timeDict.hour, timeDict.minute, timeDict.second];	

func add_line(line):
	$console_text.add_text(get_time_string() + line + "\n")
	if $console_text.get_line_count() > $console_text.get_visible_line_count() + 100:
		$console_text.remove_line(0)

func _process(delta):
	pass
	# add_line("ds")

